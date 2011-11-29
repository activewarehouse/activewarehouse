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
      
      attr_accessor :new_records_only, :new_records_dimension, :new_records_offset, :new_records_record
      
      def sanitize(value)
        result = value
        if value.is_a?(Date) || value.is_a?(DateTime) || value.is_a?(Time)
          result = value.to_s(:db)
        end
        connection.quote(result)
      end
      
      def query(*args)
        options = parse_query_args(*args)
        # puts "\n#{self.class.name}.query(#{options.inspect})\n"
        
        # throw an error if there is no column and/or row
        cstage     = options[:cstage] || 0
        rstage     = options[:rstage] || 0
        filters    = options[:filters] || {}
        conditions = options[:conditions] || nil
        joins      = options[:joins] || nil
        limit      = options[:limit] || nil
        order      = options[:order] || nil
        
        column_dimension_name = options[:column_dimension_name] || options[:column]
        column_dimension      = fact_class.dimension_class(column_dimension_name)
        column_hierarchy      = cube_class.dimension_hierarchy(column_dimension_name)
        
        if cstage.to_s == 'all'
          current_column_name =  "#{column_dimension_name}_all"
          full_column_name    =  "'all'"
        else
          current_column_name   = column_hierarchy[cstage]
          full_column_name      = "#{column_dimension_name}_#{current_column_name}"
        end
        
        row_dimension_name    = options[:row_dimension_name] || options[:row]
        row_dimension         = fact_class.dimension_class(row_dimension_name)
        row_hierarchy         = cube_class.dimension_hierarchy(row_dimension_name)
        
        if rstage.to_s == 'all'
          current_row_name =  "#{row_dimension_name}_all"
          full_row_name    =  "'all'"
        else
          current_row_name   = row_hierarchy[rstage]
          full_row_name      = "#{row_dimension_name}_#{current_row_name}"
        end
        
        # if they try to query a hierarchy not in this cube, fallback on super (no_aggregate) query method
        ach = options[:column_hierarchy_name]
        cch = cube_class.dimensions_hierarchies[column_dimension_name]
        arh = options[:row_hierarchy_name]
        crh = cube_class.dimensions_hierarchies[row_dimension_name]
        if ((ach && (ach != cch)) ||(arh && (arh != crh)))
          return super
        end
        
        dimension_levels = {}
        dimension_levels[column_dimension] = (cstage.to_s == 'all') ? 0 : [(cstage + 1), column_hierarchy.count].min
        dimension_levels[row_dimension] =  (rstage.to_s == 'all') ? 0 : [(rstage + 1), row_hierarchy.count].min
        
        # build the where clause
        where_clause = []
        
        #  I don't think I want these
        where_clause << "#{full_column_name} is not null" unless cstage == 'all'
        where_clause << "#{full_row_name} is not null" unless rstage == 'all'
        
        # process all filters
        filters.each do |key, value|
          dimension_name, column = key.split('.')
          
          dim_class     = fact_class.dimension_class(dimension_name.to_sym)
          dim_hierarchy = cube_class.dimension_hierarchy(dimension_name.to_sym)
          dim_level     = dim_hierarchy.index(column.to_sym)
          name          = "#{dimension_name}_#{column}"
          
          if dim_level
            if value
              
              if value.is_a?(Range)
                where_clause << "(#{name} >= #{sanitize(value.begin)}) AND (#{name} <= #{sanitize(value.end)})"
              elsif value == :not_null
                where_clause << "#{name} IS NOT NULL"
              elsif value == :not_blank
                where_clause << "#{name} IS NOT NULL AND #{name} != ''"
              elsif (value.nil? || value == :null)
                where_clause << "#{name} IS NULL"
              else
                where_clause << "#{name} = #{sanitize(value)}"
              end
            else
              where_clause << "#{name} IS NOT NULL"
            end
            
            unless [column_dimension_name, row_dimension_name].include?(dimension_name)
              current_level = dimension_levels[dim_class] || 0
              dimension_levels[dim_class] = [current_level, (dim_level + 1)].max
            end
            
          end
          
        end
        
        # default order by row, then column
        unless order
          order_fields = []
          order_fields << "#{full_row_name} DESC" unless rstage == 'all'
          order_fields << "#{full_column_name} DESC" unless cstage == 'all'
          order = order_fields.join(', ')
        end
        
        #  see if the levels are all > for any non-base dim
        use_base = true
        aggregate_options = cube_class.aggregate_options
        aggregate_levels = aggregate_dimension_fields.collect{ |dim, levels| 
          l = [[(dimension_levels[dim] || 0), levels.count].min, 0].max
          if !in_base?(dim, aggregate_options) && (l > 0)
            use_base = false
          end
          l
        }
        # puts "should you use the base for this query? #{use_base}"
        
        if use_base && aggregate_options[:base]
          aggregate_options[:base].query(*args)
        else
          query_table_name = aggregate_rollup_name(aggregate_table_name(options), aggregate_levels)
          
          aggregate_column_names = aggregate_fields.collect do |c|
            
            if c.is_additive? || aggregate_options[:always_use_fact]
              # if strategy is a count or sum, we need to sum it. avg, min, and max run (though avg seems like it will be wrong often)
              "#{[:min,:max,:avg].include?(c.strategy_name) ? c.strategy_name : :sum}(#{c.label_for_table}) AS '#{c.label}'"
            elsif [:min,:max].include?(c.strategy_name)
              # if min, and max, will work even if not additive
              "#{c.strategy_name}(#{c.label_for_table}) AS '#{c.label}'"
            else
              # otherwise, for a nonadditive, non min/max, just return 0 rather than be an incorrect value
              "0 AS '#{c.label}'"
            end
            
          end.compact
          
          # build the SQL query
          sql = ''
          sql << "SELECT\n"
          sql << "#{full_column_name} AS '#{current_column_name}',\n"
          sql << "#{full_row_name} AS '#{current_row_name}',\n"
          sql << (aggregate_column_names.join(",\n") + "\n")
          sql << "FROM #{query_table_name}\n"
          sql << "WHERE (#{where_clause.join(") AND\n(")})\n"
          sql << "AND (#{sanitize(conditions)})\n" if conditions
          sql << "GROUP BY #{full_column_name}, #{full_row_name}\n"
          sql << "ORDER BY #{order}\n" if order
          sql << "LIMIT #{limit}\n" if limit

          # execute the query and return the results as a CubeQueryResult object
          # puts "\n\n aggregate_fields: #{aggregate_fields.inspect}\n\n"
          result = ActiveWarehouse::CubeQueryResult.new(aggregate_fields)
          rows = connection.select_all(sql)
          rows.each do |row|
            # puts "\n\n result row: #{row.inspect}\n\n"
            result.add_data(row.delete(current_row_name.to_s),
                            row.delete(current_column_name.to_s),
                            row) # the rest of the members of row are the fact columns
          end
          result
        end
      end

      # Build and populate the data store
      def populate(options={})
        # puts "PipelinedRolapAggregate::populate #{options.inspect}"
        @new_records_record = nil
        
        # see if the options mean to do new records only
        if(options[:new_records_only])
          # need to know the name of the dimension and field to use to find new only
          @new_records_only = true
          @new_records_dimension = options[:new_records_only][:dimension] || :date
          @new_records_offset = options[:new_records_only][:buffer] || 1
        else
          @new_records_only = false
        end
        
        create_and_populate_aggregate(options)
      end
      
      def create_and_populate_aggregate(options={})
        # puts "PipelinedRolapAggregate::create_and_populate_aggregate #{options.inspect}"
        base_name = aggregate_table_name(options)
        dimension_fields = aggregate_dimension_fields
        aggregate_levels = dimension_fields.collect{|dim, levels|
          min_level = create_all_level?(dim, options) ? 0 : 1
          (min_level..levels.count).collect.reverse
        }.sequence
        
        # puts "aggregate_levels:\n#{aggregate_levels.inspect}"
        
        # first time through always use the fact table, don't after that if piplining
        options.merge!({:use_fact => true})

        find_latest_record(base_name, dimension_fields, aggregate_levels.first, options)
        
        aggregate_levels.each do |levels|
          create_aggregate_table(base_name, dimension_fields, levels, options)
          populate_aggregate_table(base_name, dimension_fields, levels, options)
          options.delete(:use_fact) unless options[:always_use_fact]
        end
        
      end
      
      def create_all_level?(dim, options)
        # see if a base is defined, if not, always make all levels
        # if there is a base, see if this is a dim in the base
        # if it is in the base, then we need to do all, if it is not in base, do not do all
        !options[:base] || in_base?(dim, options)
      end

      def in_base?(dim, options)
        options[:base] && options[:base].dimension_classes.include?(dim)
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
        table_options = options[:aggregate_table_options] || {}
        
        # # truncate if configured to, otherwise, just pile it on.
        if (options[:truncate] && connection.tables.include?(table_name))
          connection.drop_table(table_name)
        end
        
        unique_index_columns = []
        index_columns = []
        
        if !connection.tables.include?(table_name)
          aggregate_table_options = (options[:aggregate_table_options] || {}).merge({:id => false})
          # puts "create_table: #{table_name}"
          connection.create_table(table_name, aggregate_table_options) do |t|
            dimension_fields.each_with_index do |pair, i|
              dim = pair.first
              levels = pair.last
              max_level = current_levels[i]
              # puts "dim.name = #{dim.name}, max = #{max_level}, i = #{i}"
              levels.each_with_index do |field, j|
                break if (j >= max_level)
                column_options = {:null=>false}
                # unique_index_columns << field.label if (j == (max_level-1))
                
                # if it is a string or text column, then include the limit with the options
                if [:string, :text].include?(field.column_type)
                  column_options[:limit] = field.limit
                  column_options[:default] = ''
                elsif [:primary_key, :integer, :float, :decimal, :boolean].include?(field.column_type)
                  column_options[:default] = 0
                end
                
                unique_index_columns << field.label
                index_columns << field.label
                t.column(field.label, field.column_type, column_options)
              end
            end
            
            aggregate_fields.each do |field|
              af_opts = {}
              
              # By default the aggregate field column type will be a count
              aggregate_type = :integer
              af_opts[:limit] = 8
              
              # But, if type is a decimal, and you do a sum or avg (not a count) then keep it a decimal
              if [:float, :decimal].include?(field.type) && field.strategy_name != :count
                af_opts[:limit] = field.type == :integer ? 8 : field.limit
                af_opts[:scale] = field.scale if field.scale
                af_opts[:precision] = field.precision if field.precision
                aggregate_type = field.column_type
              end
              
              t.column(field.label_for_table, aggregate_type, af_opts)
            end
            
          end
          
          # add index per dimension here (not for aggregate fields)
          index_columns.each{ |dimension_column|
            # puts "making index for: #{table_name} on: #{dimension_column}"
            connection.add_index(table_name, dimension_column, :name => "by_#{dimension_column}")
          }
          
          # Add a unique index for the 
          unless unique_index_columns.empty?
            # puts "making unique index for: #{table_name} on: #{unique_index_columns.inspect}"
            connection.add_index(table_name, unique_index_columns, :unique => true, :name => "by_unique_dims") 
          end
          
          # puts "create_aggregate_table end"
          table_name
        end
        
      end
      
      def find_latest_record(base_name, dimension_fields, current_levels, options={})
        target_rollup = aggregate_rollup_name(base_name, current_levels)
        new_rec_dim_class = self.new_records_only ? fact_class.dimension_class(new_records_dimension) : nil

        if (self.new_records_only && !self.new_records_record && connection.tables.include?(target_rollup))
          latest = nil
          new_records_field = dimension_fields[new_rec_dim_class].last
          find_latest_sql = "SELECT #{new_records_field} AS latest FROM #{target_rollup} GROUP BY #{new_records_field} ORDER BY #{new_records_field} DESC LIMIT #{[(new_records_offset - 1), 0].max}, 1"
          # puts "\n\nfind_latest_sql = #{find_latest_sql}\n\n"
          latest = connection.select_one(find_latest_sql);
          
          if latest
            # puts "found latest: #{latest.inspect}"
            # puts "find latest for dim: #{new_rec_dim_class.name}.where(#{new_records_field.name} => #{latest['latest']}).first"
            self.new_records_record = new_rec_dim_class.where(new_records_field.name=>latest['latest']).first
          else
            self.new_records_record = nil
          end
        end
        
        # puts "self.new_records_record = #{self.new_records_record.inspect}"
        
      end
      
      def populate_aggregate_table(base_name, dimension_fields, current_levels, options={})
        target_rollup = aggregate_rollup_name(base_name, current_levels)
        new_rec_dim_class = self.new_records_only ? fact_class.dimension_class(new_records_dimension) : nil
        
        dimension_column_names = []
        dimension_column_group_names = []
        
        load_dimension_column_names = []
        load_aggregate_column_names = []
        
        where_clause = ""
        delete_sql = nil
        
        if (options[:use_fact])
          from_tables_and_joins = tables_and_joins
        else
          from_tables_and_joins = parent_aggregate_rollup_name(base_name, dimension_fields, current_levels)
        end

        dimension_fields.each_with_index do |pair, i|
          dim, levels = pair
          max_level = current_levels[i]

          if self.new_records_only && new_rec_dim_class == dim  && !options[:truncate]

            if new_records_record && max_level > 0
              # puts "add in a new records only condition..."
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
              
              # puts "create new records only condition #{where_clause}"
              
              # no need to delete now that we're using the replace bulk load option, 
              # and have created unique keys on the aggregate to make that work
              unless options[:replace]
                delete_sql = "DELETE FROM\t#{target_rollup}\nWHERE\t\t(" + delete_fields.join(" AND\n\t\t") + ") "
              end
              
            else
              delete_sql = "TRUNCATE TABLE #{target_rollup}"
            end
          end

          levels.each_with_index do |field, j|
            break if (j >= max_level)
            
            field_default = "''"
            if [:primary_key, :integer, :float, :decimal, :boolean].include?(field.column_type)
              field_default = 0
            end
            
            if options[:use_fact]
              dimension_column_names        << "coalesce(#{field.table_alias}.#{field.name}, #{field_default}) as #{field.table_alias}_#{field.name}"
              load_dimension_column_names   << "#{field.table_alias}_#{field.name}"
              dimension_column_group_names  << "#{field.table_alias}.#{field.name}"
            else
              dimension_column_names        << field.label
              load_dimension_column_names   << field.label
              dimension_column_group_names  << field.label
            end
          end

        end

        aggregate_column_names = aggregate_fields.collect do |c|
          result = nil
          if options[:use_fact]
            # if we are going against the fact, all strategies are legit - whew!

            if c.is_additive? || options[:always_use_fact] || [:min,:max].include?(c.strategy_name)
              distinct = c.is_distinct? ? 'distinct ' : ''
              result = "#{c.strategy_name}(#{distinct}#{fact_class.table_name}.#{c.name}) AS #{c.label_for_table}"
            end
          else
            # if we are are populating from an aggregate table, check if it is additive
            if c.is_additive?
              # if strategy is a count or sum, we need to sum it. avg, min, and max run (though avg seems like it will be wrong often)
              result = "#{[:min,:max,:avg].include?(c.strategy_name) ? c.strategy_name : :sum}(#{c.label_for_table}) AS #{c.label_for_table}"
            elsif [:min,:max].include?(c.strategy_name)
              # if min, and max, will work even if not additive
              result = "#{c.strategy_name}(#{c.label_for_table}) AS #{c.label_for_table}"
            end
          end
          load_aggregate_column_names << c.label_for_table if result
          result
        end.compact

        # load_aggregate_column_names = aggregate_fields.collect{|c| c.label_for_table}

        options[:fields] = {} unless options[:fields]
        options[:fields][:delimited_by] = ','
        options[:fields][:enclosed_by] = '"'

        outfile = aggregate_temp_file(target_rollup)

        sql =  "SELECT\t\t#{(dimension_column_names + aggregate_column_names).join(",\n\t\t")}\n"
        sql << "FROM\t\t#{from_tables_and_joins}\n"
        sql << where_clause + "\n"
        sql << "GROUP BY\t#{dimension_column_group_names.join(",\n\t\t")}\n" if dimension_column_group_names.size > 0
        sql << "\nINTO OUTFILE '#{outfile}'\n"
        sql << "FIELDS TERMINATED BY '#{options[:fields][:delimited_by]}'\n"
        sql << "         ENCLOSED BY '#{options[:fields][:enclosed_by]}'\n"

        
        puts sql + "\n--------------------------------------------------------------------------------\n"

        connection.transaction do
          connection.execute(sql)
        end

        connection.transaction do
          # TODO: remove the appropriate records
          # if new rec only, and (0) fields for the new rec dim, truncate table before loading, as this is a full load.
          if delete_sql
            puts delete_sql + "\n--------------------------------------------------------------------------------\n"
            connection.execute(delete_sql)
          end
          
          # connection.bulk_load(outfile, target_rollup, options.merge({:replace=>true}))
          options[:columns] = load_dimension_column_names + load_aggregate_column_names
          # puts options.inspect + "\n--------------------------------------------------------------------------------\n"
          connection.bulk_load(outfile, target_rollup, options)
        end
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
      def aggregate_table_name(options={})
        "#{options[:prefix]}#{cube_class.name.tableize.singularize}_agg"
      end
      
      def aggregate_dimension_fields
        # puts "aggregate_dimension_fields"
        dim_cols = OrderedHash.new
        
        cube_class.dimensions_hierarchies.each do |dimension_name, hierarchy_name|
          dimension_class = fact_class.dimension_class(dimension_name)
          dim_cols[dimension_class] = []

          cube_class.dimension_hierarchy(dimension_name).each do |level|
            # puts "level.to_s = #{level.to_s}"
            column = dimension_class.columns_hash[level.to_s]
            dim_cols[dimension_class] << Field.new( dimension_class,
                                                    column.name,
                                                    column.type,
                                                    { 
                                                      :limit       => column.limit,
                                                      :scale       => column.scale,
                                                      :precision   => column.precision,
                                                      :table_alias => dimension_name 
                                                    })
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
