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
    class PipelinedRolapAggregate < NoAggregate
      include RolapCommon
      
      attr_accessor :new_records_only, :new_records_dimension, :new_records_record

      def query(*args)
        options = parse_query_args(*args)

        column_dimension_name = options[:column_dimension_name] || options[:column]
        row_dimension_name = options[:row_dimension_name] || options[:row]

        # if they try to query a hierarchy not in this cube, fallback on super (no_aggregate) query method
        ach = options[:column_hierarchy_name]
        cch = cube_class.dimensions_hierarchies[column_dimension_name]
        arh = options[:row_hierarchy_name]
        crh = cube_class.dimensions_hierarchies[row_dimension_name]
        if ((ach && (ach != cch)) ||(arh && (arh != crh)))
          return super
        end
        
        # throw an error if there is no column and/or row
        cstage = options[:cstage] || 0
        rstage = options[:rstage] || 0
        filters = options[:filters] || {}
        conditions = options[:conditions] || nil
        
        column_dimension = fact_class.dimension_class(column_dimension_name)
        column_hierarchy = dimension_hierarchy(column_dimension_name)        
        row_dimension = fact_class.dimension_class(row_dimension_name)
        row_hierarchy = dimension_hierarchy(row_dimension_name)

        dimension_levels = {}
        dimension_levels[column_dimension] = [(cstage + 1), column_hierarchy.count].min
        dimension_levels[row_dimension] = [(rstage + 1), row_hierarchy.count].min

        current_column_name = column_hierarchy[cstage]
        current_row_name = row_hierarchy[rstage]
        full_column_name = "#{column_dimension_name}_#{current_column_name}"
        full_row_name = "#{row_dimension_name}_#{current_row_name}"

        # build the where clause
        where_clause = []
        where_clause << "#{full_column_name} is not null"
        where_clause << "#{full_row_name} is not null"

        # process all filters
        filters.each do |key, value|
          dimension_name, column = key.split('.')

          dim_class     = fact_class.dimension_class(dimension_name.to_sym)
          dim_hierarchy = dimension_hierarchy(dimension_name.to_sym)
          dim_level     = dim_hierarchy.index(column.to_sym)
          name          = "#{dimension_name}_#{column}"
          
          if dim_level
            if value
              where_clause << "#{name} = #{connection.quote(value)}"
            else
              where_clause << "#{name} is null"
            end
            
            unless [column_dimension_name, row_dimension_name].include?(dimension_name)
              current_level = dimension_levels[dim_class] || 0
              dimension_levels[dim_class] = [current_level, (dim_level + 1)].max
            end

          end
          
        end

        aggregate_levels = aggregate_dimension_fields.collect{ |dim, levels| 
          [[(dimension_levels[dim] || 0), levels.count].min, 0].max
        }

        query_table_name = aggregate_rollup_name(aggregate_table_name, aggregate_levels)

        # build the SQL query
        sql = ''
        sql << "SELECT\n"
        sql << "#{full_column_name} AS #{current_column_name},\n"
        sql << "#{full_row_name} AS #{current_row_name},\n"
        sql << (aggregate_fields.collect{|c| "#{c.label_for_table} as '#{c.label}'"}.join(",\n") + "\n")
        sql << "FROM #{query_table_name}\n"
        sql << "WHERE (#{where_clause.join(" AND\n")})" if where_clause.length > 0

        if conditions
          sql << " AND\n (#{conditions})"
        end
        
        # execute the query and return the results as a CubeQueryResult object
        result = ActiveWarehouse::CubeQueryResult.new(aggregate_fields)
        rows = connection.select_all(sql)
        rows.each do |row|
          result.add_data(row.delete(current_row_name.to_s),
                          row.delete(current_column_name.to_s),
                          row) # the rest of the members of row are the fact columns
        end
        result
      end


      # Build and populate the data store
      def populate(options={})
        # puts "PipelinedRolapAggregate::populate #{options.inspect}"
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
        where_clause = ""
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
              where_clause = "WHERE\t\t(" + new_rec_fields.join(" AND\n\t\t") + ") "
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

        outfile = aggregate_temp_file(target_rollup)

        sql =  "SELECT\t\t#{(dimension_column_names + aggregate_column_names).join(",\n\t\t")}\n"
        sql << "FROM\t\t#{from_tables_and_joins}\n"
        sql << where_clause + "\n"
        sql << "GROUP BY\t#{dimension_column_group_names.join(",\n\t\t")}\n" if dimension_column_group_names.size > 0
        sql << "\nINTO OUTFILE '#{outfile}'\n"
        if options[:fields]
          sql << " FIELDS"
          sql << " TERMINATED BY '#{options[:fields][:delimited_by]}'\n" if options[:fields][:delimited_by]
          sql << " ENCLOSED BY '#{options[:fields][:enclosed_by]}'\n" if options[:fields][:enclosed_by]
        end
        sql << " IGNORE #{options[:ignore]} LINES" if options[:ignore]
        sql << " (#{options[:columns].join(',')})" if options[:columns]
        
        puts sql + "\n--------------------------------------------------------------------------------\n"
        connection.execute(sql)
      
        # TODO: remove the appropriate records
        # if new rec only, and (0) fields for the new rec dim, truncate table before loading, as this is a full load.
        if delete_sql
          # puts delete_sql + "\n--------------------------------------------------------------------------------\n"
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
          dimension_class = fact_class.dimension_class(dimension_name)
          dim_cols[dimension_class] = []

          dimension_hierarchy(dimension_name).each do |level|
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
      
      def dimension_hierarchy(dimension_name)
        hierarchy_name = cube_class.dimensions_hierarchies[dimension_name]
        dimension_class = fact_class.dimension_class(dimension_name)
        levels = hierarchy_name ? dimension_class.hierarchy_levels[hierarchy_name] || [hierarchy_name] : ['id']
        levels.uniq
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
