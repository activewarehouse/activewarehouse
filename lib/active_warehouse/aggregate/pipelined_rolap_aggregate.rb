require 'tempfile'

module ActiveWarehouse #:nodoc
  module Aggregate #:nodoc
    
    # A Pipelined implementation of a ROLAP engine that stores all possible
    # combinations
    # of fact and dimensional values for a specific cube.
    # 
    # This implementation attempts to reduce the amount of work required
    # by aggregating facts in a pipelined fashion.  This means that smaller
    # aggregates are generated from a preceding aggregate, in order to avoid
    # having to query the entire raw data set for every aggregate.
    # 
    # E.g.
    # ABCD -> ABC -> AB -> A -> *all*
    class PipelinedRolapAggregate < Aggregate
      include RolapCommon
      
      attr_accessor :new_records_only, :new_records_dimension, :new_records_record
      
      # Build and populate the data store
      def populate(options={})
        puts "PipelinedRolapAggregate::populate #{options.inspect}"
        @new_records_record = nil

        # see if the options mean to do new records only
        if(options[:new_records_only])
          # need to know the name of the dimension and field to use to find new only
          @new_records_only = true
          @new_records_dimension = options[:new_records_only]
        else
          @new_records_only = false
        end
        
        create_and_populate_aggregate(options)
      end
      
      def create_and_populate_aggregate(options={})
        # puts "PipelinedRolapAggregate::create_and_populate_aggregate #{options.inspect}"
        base_name = aggregate_table_name
        dimension_fields = aggregate_dimension_fields
        aggregate_levels = dimension_fields.collect{|dim, levels| 
          (0..levels.count).collect.reverse
        }.sequence
        
        # first time through use the fact table, don't after that
        options.merge!({:use_fact => true})
        aggregate_levels.each do |levels|
          create_aggregate_table(base_name, dimension_fields, levels, options)
          populate_aggregate_table(base_name, dimension_fields, levels, options)
          options.delete(:use_fact)
        end
        
      end

      # build and populate a table which group by's all dimension columns.
      # this should include all the columns from the hierarchies in the dimension
      # should it have the column id levels? only if in the hierarchy
      # if there is no hierarchy specified, see if the hierachy name is a column, use that
      # if not, just use the dim's id
      # so a product dimension with no hierarchy specified should by just product_id
      def create_aggregate_table(base_name, dimension_fields, current_levels, options)
        # puts "create_aggregate_table start: #{current_levels.inspect}"
        
        table_name = aggregate_rollup_name(base_name, current_levels)

        # # truncate if configured to, otherwise, just pile it on.
        if (options[:truncate] && connection.tables.include?(table_name))
          connection.drop_table(table_name)
        end

        if !connection.tables.include?(table_name)
          
          ActiveRecord::Base.transaction do
            connection.create_table(table_name, :id => false) do |t|

              dimension_fields.each_with_index do |pair, i|
                dim = pair.first
                levels = pair.last
                max_level = current_levels[i]
                # puts "create_aggregate_table: dim.name = #{dim.name}, max = #{max_level}, i = #{i}"
                levels.each_with_index do |field, j|
                  break if (j >= max_level)
                  t.column(field.label, field.column_type)
                end
              end

              aggregate_fields.each do |field|
                options = {}
                options[:limit] = field.type == :integer ? 8 : field.limit
                options[:scale] = field.scale if field.scale
                options[:precision] = field.precision if field.precision
                t.column(field.label_for_table, field.column_type, options)
              end
              
            end
            
            # TODO: add index per dimension here (not for aggregates)

          end
          # puts "create_aggregate_table end"
          table_name
        end

      end
      
      def populate_aggregate_table(base_name, dimension_fields, current_levels, options={})
        target_rollup = aggregate_rollup_name(base_name, current_levels)
        new_rec_dim_class = self.new_records_only ? Dimension.to_dimension(new_records_dimension) : nil

        dimension_column_names = []
        dimension_column_group_names = []
        where = []
        delete_sql = nil
        
        if (options[:use_fact])
          if (self.new_records_only && !self.new_records_record)
            new_records_field = dimension_fields[new_rec_dim_class].last
            latest = connection.select_all("SELECT MAX(#{new_records_field}) AS latest FROM #{target_rollup}").first['latest']
            if latest
              self.new_records_record = new_rec_dim_class.where(new_records_field.name=>latest).first
            else
              self.new_records_record = nil
            end
          end

          from_tables_and_joins = tables_and_joins
        else
          from_tables_and_joins = parent_aggregate_rollup_name(base_name, dimension_fields, current_levels)
        end

        dimension_fields.each_with_index do |pair, i|
          dim, levels = pair
          max_level = current_levels[i]

          if self.new_records_only && new_rec_dim_class == dim

            if new_records_record && max_level > 0
              new_rec_fields = []
              delete_fields = []
              levels.each_with_index do |field, j|
                break if (j >= max_level)
                new_rec_value = new_records_record.send(field.name)

                if options[:use_fact]
                  new_rec_fields << "(#{field.table_alias}.#{field.name} >= '#{new_rec_value}')"
                else
                  new_rec_fields << "(#{field.label} >= '#{new_rec_value}')"
                end

                delete_fields << "(#{field.label} >= '#{new_rec_value}')"

              end
              where = "WHERE\t\t(" + new_rec_fields.join(" AND\n\t\t") + ") "
              delete_sql = "DELETE FROM\t#{target_rollup}\nWHERE\t\t(" + delete_fields.join(" AND\n\t\t") + ") "
            else
              delete_sql = "TRUNCATE TABLE #{target_rollup}"
            end
          end

          levels.each_with_index do |field, j|
            break if (j >= max_level)
            if options[:use_fact]
              dimension_column_names << "#{field.table_alias}.#{field.name} as #{field.table_alias}_#{field.name}"
              dimension_column_group_names << "#{field.table_alias}.#{field.name}"
            else
              dimension_column_names << field.label
              dimension_column_group_names << field.label
            end
          end

        end

        aggregate_column_names = aggregate_fields.collect do |c|
          if options[:use_fact]
            "#{c.strategy_name}(#{c.name}) AS #{c.label_for_table}"
          else
            "#{c.strategy_name == :avg ? :avg : :sum}(#{c.label_for_table}) AS #{c.label_for_table}"
          end
        end

        sql = <<-SQL
SELECT#{"\t\t" + (dimension_column_names + aggregate_column_names).join(",\n\t\t")}
FROM#{"\t\t" + from_tables_and_joins}
#{where}
#{"GROUP BY" if (dimension_column_names && (dimension_column_names.size > 0))}
#{"\t\t" + dimension_column_group_names.join(",\n\t\t")}
SQL

        outfile = aggregate_temp_file(target_rollup)
        q = "\nINTO OUTFILE '#{outfile}'"
        if options[:fields]
          q << " FIELDS"
          q << " TERMINATED BY '#{options[:fields][:delimited_by]}'" if options[:fields][:delimited_by]
          q << " ENCLOSED BY '#{options[:fields][:enclosed_by]}'" if options[:fields][:enclosed_by]
        end
        q << " IGNORE #{options[:ignore]} LINES" if options[:ignore]
        q << " (#{options[:columns].join(',')})" if options[:columns]

        sql = sql + q
        
        puts sql + "\n--------------------------------------------------------------------------------\n"
        connection.execute(sql)
      
        # TODO: remove the appropriate records
        # if new rec only, and (0) fields for the new rec dim, truncate table before loading, as this is a full load.
        if delete_sql
          puts delete_sql + "\n--------------------------------------------------------------------------------\n"
          connection.execute(delete_sql)
        end
        
        connection.bulk_load(outfile, target_rollup)
      end

      def parent_aggregate_rollup_name(base_name, dimension_fields, current_levels)
        parent_levels = current_levels.clone
        max_levels = dimension_fields.collect{|dim, levels|
          levels.count
        }
        current_levels.each_with_index do |level, i|
          if level < max_levels[i]
            parent_levels[i] = level + 1
            break
          end
        end
        aggregate_rollup_name(base_name, parent_levels)
      end

      def aggregate_rollup_name(table_name, current_levels)
        table_name + '_' + current_levels.join('_')
      end

      def aggregate_temp_file(aggregate_name)
        local_dir = temp_file_dir(aggregate_name)
        ts = Time.now.strftime("%Y%m%d%H%M%S")
        File.join(local_dir, ts + ".csv")
      end

      def temp_file_dir(aggregate_name)
        base_path = if defined?(Rails.root) && Rails.root
          File.expand_path(Rails.root)
        else
          File.expand_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
        end
        local_dir = File.join(base_path, "tmp", "active_warehouse", aggregate_name)
        
        # make the dir and make sure it is writable, as mysqld needs access to this
        FileUtils.mkdir_p(local_dir)
        FileUtils.chmod(0777, local_dir)
        
        local_dir
      end
      
      # The table name to use for the rollup
      def aggregate_table_name
        "#{cube_class.name.tableize.singularize}_agg"
      end
      
      def aggregate_dimension_fields
        dim_cols = OrderedHash.new
        
        cube_class.dimensions_hierarchies.each do |dimension_name, hierarchy_name|
          dimension_class = cube_class.fact_class.dimension_class(dimension_name)
          dim_cols[dimension_class] = []

          levels = hierarchy_name ? dimension_class.hierarchy_levels[hierarchy_name] || [hierarchy_name] : ['id']
          levels.uniq.each do |level|
            # puts "level.to_s = #{level.to_s}"
            column = dimension_class.columns_hash[level.to_s]
            dim_cols[dimension_class] << Field.new( dimension_class,
                                                    column.name,
                                                    column.type,
                                                    :table_alias=>dimension_name)
          end
        end
        dim_cols
      end
      
    end

  end

end

class Array

  # The accumulation is a bit messy but it works ;-)
  def sequence(i = 0, *a)
    return [a] if i == size
    self[i].map {|x|
      sequence(i+1, *(a + [x]))
    }.inject([]) {|m, x| m + x}
  end

end
