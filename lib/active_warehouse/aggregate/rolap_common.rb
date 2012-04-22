module ActiveWarehouse
  module Aggregate
    module RolapCommon

      # Convert all of the dimensions that the cube may be pivotted on into an
      # array of Field instances, one per column in the each dimension hierarchy.
      # 
      # This method will also filter out duplicates so that a dimension
      # attribute will only appear once in the aggregate even
      # if it is used in multiple hierarchies.
      #
      # Only dimension attributes which are defined in a hierarchy in the
      # dimension will be included in the aggregate, unless none are in which
      # case every dimension field is used.
      def dimensions_to_columns(max_levels={})
        columns = []

        cube_class.dimensions_hierarchies.each do |dimension_name, hierarchy_name|
          dimension_class = cube_class.fact_class.dimension_class(dimension_name)
          dimension_table_name = dimension_class.table_name

          if !dimension_table_name
            raise "Did not find #{dimension_name} as a :belongs_to relationship in #{fact_class}"
          end

          levels = dimension_class.hierarchy_levels[hierarchy_name]

          # puts "hierarchy_name: #{hierarchy_name}"
          # puts "levels: #{levels.inspect}"
          
          if levels
            max_level = max_levels[dimension_name] || levels.size
            current_level = 1
            levels.each do |level|
              break if (current_level > max_level)
              current_level = current_level + 1
              next if columns.find{|c| c.table_alias == dimension_name && c.name == level.to_s}
              column = dimension_class.columns_hash[level.to_s]
              # puts "column.inspect : #{column.inspect}"
              columns << Field.new(dimension_class,
                                   column.name,
                                   column.type,
                                   :table_alias=>dimension_name)
            end
          else
            next if columns.find{|c| c.table_alias == dimension_name && c.name == hierarchy_name}
            column = dimension_class.columns_hash[:id]
            columns << Field.new(dimension_class,
                                 dimension_class.foreign_key,
                                 column.type,
                                 :table_alias=>dimension_name)
          end


        end
        columns
      end
      
      # Get a String that contains the SQL fragment for selecting the summed
      # fact columns. Each column is aliased and then appended with "_sum"
      # before joining together with commas.
      def aggregated_fact_column_sql
        aggregate_fields.collect { |c| 
          "#{c.strategy_name}(#{c.from_table_name}.#{c.name}) AS #{c.label_for_table}"
        }.join(",")
      end
      
      # Convenience accessor that delegates to cube class method aggregate_fields.
      # Returns an array of AggregateField instances, which are the fact columns
      # from the fact table.
      # This is used by PipelinedRolapAggregate
      def aggregate_fields
        cube_class.aggregate_fields
      end
      
      # The SQL fragment for tables and joins which is used during the population
      # of the "flattened" cube
      # This is used by PipelinedRolapAggregate
      def tables_and_joins
        sql = "#{fact_class.table_name}"
        cube_class.dimensions_hierarchies.each do |dimension_name, hierarchy_name|
          dimension_table_name = fact_class.dimension_class(dimension_name).table_name
          sql += " LEFT JOIN #{dimension_table_name} as #{dimension_name}"
          sql += " ON #{fact_class.table_name}."
          sql += "#{fact_class.dimension_relationships[dimension_name].foreign_key}"
          sql += " = #{dimension_name}.id\n"
        end
        sql
      end
      
      # The table name to use for the rollup
      def rollup_table_name
        "#{cube_class.name.tableize.singularize}_rollup"
      end

    end
  end
end
