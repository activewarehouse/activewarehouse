# Source file that contains a basic ROLAP engine implementation.

module ActiveWarehouse #:nodoc
  module Aggregate #:nodoc

    # Basic implementation of a ROLAP engine that stores all possible combinations
    # of fact and dimensional values for a specific cube.
    class RolapAggregate < Aggregate
      include RolapCommon

      # Build and populate the data store
      def populate(options={})
        populate_rollup_cube
      end

      # Query the aggregate, returning a QueryResult object
      def query(*args)
        options = parse_query_args(*args)

        column_dimension_name = options[:column_dimension_name]
        column_hierarchy_name = options[:column_hierarchy_name]
        row_dimension_name = options[:row_dimension_name]
        row_hierarchy_name = options[:row_hierarchy_name]
        conditions = options[:conditions]
        cstage = options[:cstage]
        rstage = options[:rstage]
        filters = options[:filters]

        column_dimension = fact_class.dimension_class(column_dimension_name)
        column_hierarchy = column_dimension.hierarchy(column_hierarchy_name)
        row_dimension = fact_class.dimension_class(row_dimension_name)
        row_hierarchy = row_dimension.hierarchy(row_hierarchy_name)

        current_column_name = column_hierarchy[cstage]
        current_row_name = row_hierarchy[rstage]
        full_column_name = "#{column_dimension_name}_#{current_column_name}"
        full_row_name = "#{row_dimension_name}_#{current_row_name}"

        # build the SQL query
        sql = ''
        sql += 'SELECT '
        sql += "#{full_column_name} AS #{current_column_name},"
        sql += "#{full_row_name} AS #{current_row_name},"
        sql += aggregate_fields.collect{|c| "#{c.label_for_table} as '#{c.label}'"}.join(",")
        sql += " FROM #{rollup_table_name} "

        # build the where clause
        where_clause = []
        0.upto(column_hierarchy.length - 1) do |stage|
          column_name = column_hierarchy[stage]
          name = "#{column_dimension_name}_#{column_name}"
          filter_value = filters.delete(column_name)
          if filter_value
            where_clause << "#{name} = '#{filter_value}'" # TODO: protect from
          else
            where_clause << "#{name} is null" if stage > cstage
          end
        end

        0.upto(row_hierarchy.length - 1) do |stage|
          row_name = row_hierarchy[stage]
          name = "#{row_dimension_name}_#{row_name}"
          filter_value = filters.delete(row_name)
          if filter_value
            where_clause << "#{name} = '#{filter_value}'" # TODO: protect from
          else
            where_clause << "#{name} is null" if stage > rstage
          end
        end

        where_clause << "#{full_column_name} is not null"
        where_clause << "#{full_row_name} is not null"

        filters.each do |key, value|
          dimension_name, column = key.split('.')
          where_clause << "#{dimension_name}_#{column} = '#{value}'" # TODO: protect from SQL injection
        end

        sql += %Q( WHERE #{where_clause.join(" AND ")} ) if where_clause.length > 0

        if conditions
          sql += "\n WHERE\n" unless sql =~ /WHERE/i
          sql += conditions
        end

        # execute the query and return the results as a CubeQueryResult object
        result = ActiveWarehouse::CubeQueryResult.new(aggregate_fields)

        rows = connection.select_all(sql)
        #        fact_column_names = fact_class.aggregate_fields.collect{|f| f.to_s}
        rows.each do |row|
          result.add_data(row.delete(current_row_name.to_s),
                          row.delete(current_column_name.to_s),
                          row) # the rest of the members of row are the fact columns
        end
        result

      end

      protected

      # Creates the rollup table
      def create_rollup_cube_table(options={})
        # TODO: perhaps this should all be executed in a single transaction?
        connection.drop_table(rollup_table_name) if connection.tables.include?(rollup_table_name)

        ActiveRecord::Base.transaction do
          connection.create_table(rollup_table_name, :id => false) do |t|
            dimensions_to_columns.each do |c|
              t.column(c.label, c.column_type)
            end
            aggregate_fields.each do |c|
              t.column(c.label_for_table, c.column_type)
            end
          end
        end
      end

      # Builds the aggregate SQL that will be used to populate the ROLAP table.
      # This SQL is just the SELECT statement and includes all of the GROUP BYs
      # and aggregation functions.
      # 
      # +column_mask+ is an array of booleans, where true is the column to group
      # by.  The length of this array is equal to the number of columns in
      # the SELECT clause.
      def build_aggregate_sql(column_mask)
        dimension_column_names = dimensions_to_columns.collect do |c|
          "#{c.table_alias}.#{c.name}"
        end

        sql = <<-SQL
          SELECT
        #{mask_columns_with_null(dimension_column_names, column_mask).join(",")},
        #{aggregated_fact_column_sql}
          FROM #{tables_and_joins}
          SQL

          group = mask_columns_with_null(dimension_column_names, column_mask).reject{|o| o == 'null'}.join(",")
          sql += "GROUP BY #{group}" if !group.empty?
          sql
      end

      # Populate the rollup cube
      # 
      # Options:
      # * <tt>:verbose</tt>: Set to true to print info to STDOUT during building
      def populate_rollup_cube(options={})
        create_rollup_cube_table(options)
        puts "Populating rollup cube #{cube_class.name}" if options[:verbose]

        num_columns = dimensions_to_columns.size
        num_combos = (2**num_columns)-1
        puts "There are #{num_combos} combinations" if options[:verbose]
        (0..num_combos).each do |i|
          puts "Populating agg #{i} of #{num_combos}" if i % 100 == 0 if options[:verbose]
          mask = sprintf("%0#{num_columns}b", i).split(//).collect{|x| x == '1' ? true : false}

          sql = ''
          sql += "INSERT INTO #{rollup_table_name} "
          sql += build_aggregate_sql(mask)

          connection.transaction { connection.execute(sql) }
        end

        if options[:verbose]
          row_count = connection.select_value("SELECT count(*) FROM #{rollup_table_name}")
          puts "Rollup cube populated with #{row_count} rows"
        end
      end

      # Mask columns with null 
      def mask_columns_with_null(column_names, mask)
        if mask.size != column_names.size
          raise "Columns has #{column_names.size} elements, but mask has only #{mask.size}"
        end

        new_columns = []
        column_names.each_with_index{ |c,i| new_columns << (mask[i] ? c : 'null')}
        new_columns
      end

    end

  end
end
