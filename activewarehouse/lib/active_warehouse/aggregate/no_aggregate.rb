require 'set'

module ActiveWarehouse #:nodoc:
  module Aggregate #:nodoc:
    # An aggregate which goes directly to the fact and dimensions to answer questions
    class NoAggregate < Aggregate
      # Populate the aggregate (in this case it is a no-op implementation)
      def populate
        # do nothing
      end
      
      # Query the aggregate
      # def query(column_dimension_name, column_hierarchy_name,
#                 row_dimension_name, row_hierarchy_name, conditions=nil,
#                 cstage=0, rstage=0, filters={})
      
      # Query the aggregate
      def query(*args)
        options = parse_query_args(*args)
        
        column_dimension_name = options[:column_dimension_name]
        column_hierarchy_name = options[:column_hierarchy_name]
        row_dimension_name = options[:row_dimension_name]
        row_hierarchy_name = options[:row_hierarchy_name]
        conditions = options[:conditions]
        cstage = options[:cstage] || 0
        rstage = options[:rstage] || 0
        filters = options[:filters] || {}
        
        fact_class = cube_class.fact_class
        column_dimension = fact_class.dimension_class(column_dimension_name)
        column_hierarchy = column_dimension.hierarchy(column_hierarchy_name)
        row_dimension = fact_class.dimension_class(row_dimension_name)
        row_hierarchy = row_dimension.hierarchy(row_hierarchy_name)
        
        used_dimensions = Set.new
        used_dimensions.merge([column_dimension_name, row_dimension_name])
        row_dim_reflection = fact_class.dimension_relationships[row_dimension_name].dependent_dimension_reflections
        used_dimensions.merge(row_dim_reflection.collect{|d| d.name})
        col_dim_reflection = fact_class.dimension_relationships[column_dimension_name].dependent_dimension_reflections
        used_dimensions.merge(col_dim_reflection.collect{|d| d.name})
        filters.each do |k,v|
          used_dimensions << k.split('.')[0]
        end
        if conditions
          cube_class.dimensions.each do |dimension|
            if conditions =~ /#{dimension}\./i
              used_dimensions << dimension
            end
          end
        end
        
        # This method assumes at most one dimension is hierarchical dimension
        # in the query params. TODO: need to handle when both row and column
        # are hierarchical dimensions.
        hierarchical_dimension = nil
        hierarchical_dimension_name = nil
        hierarchical_stage = nil
        
        if !column_dimension.hierarchical_dimension?
          current_column_name = column_hierarchy[cstage]
        else
          hierarchical_dimension = column_dimension
          hierarchical_dimension_name = column_dimension_name
          hierarchical_stage = cstage
          current_column_name = column_hierarchy[0]
        end
        
        if !row_dimension.hierarchical_dimension?
          current_row_name = row_hierarchy[rstage]
        else
          hierarchical_dimension = row_dimension
          hierarchical_dimension_name = row_dimension_name
          hierarchical_stage = rstage
          current_row_name = row_hierarchy[0]
        end

        fact_columns = cube_class.aggregate_fields(used_dimensions).collect { |c| 
          agg_sql = ''
          quoted_label = cube_class.connection.quote_column_name(c.label)
          if hierarchical_dimension and !c.levels_from_parent.empty?
            bridge = hierarchical_dimension.bridge_class
            bridge_table_name = bridge.table_name
            levels_from_parent = bridge.levels_from_parent
            get_all = false
            c.levels_from_parent.each do |level|
              case level
              when :all
                agg_sql += "  #{c.strategy_name}(#{c.from_table_name}.#{c.name}) AS #{quoted_label})"
                get_all = true
              when :self
                agg_sql += " #{c.strategy_name}(CASE " if agg_sql.length == 0
                agg_sql += " WHEN #{bridge_table_name}.#{levels_from_parent} = 0 THEN #{c.from_table_name}.#{c.name} \n"
              when Integer  
                agg_sql += " #{c.strategy_name}(CASE " if agg_sql.length == 0              
                agg_sql += " WHEN #{bridge_table_name}.#{levels_from_parent} = #{level} then #{c.from_table_name}.#{c.name} \n"
              else
                raise ArgumentError, "Each element to :levels_from_parent option must be :all, :self, or Integer"
              end
            end
            agg_sql += " ELSE 0 END) AS #{quoted_label}" unless get_all
          else
            if c.is_distinct?
              agg_sql = "  #{c.strategy_name}(distinct #{c.from_table_name}.#{c.name}) AS #{quoted_label}" 
            else
              agg_sql = "  #{c.strategy_name}(#{c.from_table_name}.#{c.name}) AS #{quoted_label}" 
            end
          end
          agg_sql
        }.join(",\n")

        sql = ''
        sql += "SELECT\n"
        sql += "  #{column_dimension_name}.#{current_column_name},\n"
        sql += "  #{row_dimension_name}.#{current_row_name},\n"
        sql += fact_columns
        sql += "\nFROM\n"

        sql += "  #{fact_class.table_name}"
        cube_class.dimensions_hierarchies.each do |dimension_name, hierarchy_names|
          next if !used_dimensions.include?(dimension_name)
          dimension = fact_class.dimension_class(dimension_name)
          if !dimension.hierarchical_dimension? 
            if fact_class.belongs_to_relationship?(dimension_name)
              sql += "\nJOIN #{dimension.table_name} as #{dimension_name}"
              sql += "\n  ON #{fact_class.table_name}.#{fact_class.foreign_key_for(dimension_name)} = "
              sql += "#{dimension_name}.#{dimension.primary_key}"
            elsif fact_class.has_and_belongs_to_many_relationship?(dimension_name)
              relationship = fact_class.dimension_relationship(dimension_name)
              sql += "\nJOIN #{relationship.options[:join_table]} as #{dimension_name}_bridge"
              sql += "\n  ON #{fact_class.table_name}.#{fact_class.primary_key} = "
              sql += "#{dimension_name}_bridge.#{relationship.options[:foreign_key]}"
              sql += "\nJOIN #{dimension.table_name} as #{dimension_name}"
              sql += "\n  ON #{dimension_name}_bridge.#{relationship.options[:association_foreign_key]} = "
              sql += "#{dimension_name}.#{dimension.primary_key}"
            end
          else
            dimension_bridge = dimension.bridge_class
            sql += "\nJOIN #{dimension_bridge.table_name}"
            sql += "\n  ON #{fact_class.table_name}.#{fact_class.foreign_key_for(dimension_name)} = "
            sql += "#{dimension_bridge.table_name}.#{dimension.parent_foreign_key}"
            if dimension.slowly_changing_dimension?
              sql += " and (#{dimension_bridge.table_name}.#{dimension_bridge.effective_date} <= "
              sql += "#{fact_class.slowly_changes_over_name(dimension_name)}."
              sql += "#{fact_class.slowly_changes_over_class(dimension_name).sql_date_stamp} "
              sql += "and #{dimension_bridge.table_name}.#{dimension_bridge.expiration_date} >= "
              sql += "#{fact_class.slowly_changes_over_name(dimension_name)}."
              sql += "#{fact_class.slowly_changes_over_class(dimension_name).sql_date_stamp}) "
            end
            sql += "\nJOIN #{dimension.table_name} as #{dimension_name}"
            sql += "\n  ON #{dimension_bridge.table_name}.#{dimension.child_foreign_key} = "
            sql += "#{dimension_name}.#{dimension.primary_key}"
          end
        end

        # build the where clause
        # first add conditions
        where_clause = Array(conditions)
        
        # apply filters
        filters.each do |key, value|
          dimension_name, column = key.split('.')
          where_clause << "#{dimension_name}.#{column} = #{cube_class.connection.quote(value)}"
        end
        sql += %Q(\nWHERE\n  #{where_clause.join(" AND\n  ")} ) if where_clause.length > 0

        # for hierarchical dimension we need to add where clause in for drill downs
        if !hierarchical_dimension.nil?
          if where_clause.length == 0
            sql += "\n WHERE "
          else 
            sql += " \n AND "
          end
          sql += "\n #{hierarchical_dimension_name}.#{hierarchical_dimension.primary_key} IN ( "
          sql += "\n SELECT #{hierarchical_dimension.parent_foreign_key} FROM #{hierarchical_dimension.bridge_class.table_name} "
          if hierarchical_stage == 0   
            sql += "\n WHERE #{hierarchical_dimension.bridge_class.top_flag} = #{connection.send(:quote, hierarchical_dimension.bridge_class.top_flag_value)})"
          else
            sql += "\n WHERE #{hierarchical_dimension.child_foreign_key} = #{hierarchical_stage} AND #{hierarchical_dimension.levels_from_parent} = 1)"
          end
        end
        
        sql += "\nGROUP BY\n"
        sql += "  #{column_dimension_name}.#{current_column_name},\n"
        sql += "  #{row_dimension_name}.#{current_row_name}"
        
        if options[:order]
          order_by = options[:order]
          order_by = [order_by] if order_by.is_a?(String)
          order_by.collect!{ |v| cube_class.connection.quote_column_name(order_by) }
          sql += %Q(\nORDER BY\n  #{order_by.join(",\n")})
        end
        
        result = ActiveWarehouse::CubeQueryResult.new(
          cube_class.aggregate_fields(used_dimensions)
        )
        
        cube_class.connection.select_all(sql).each do |row|
          result.add_data(row.delete(current_row_name.to_s),
                          row.delete(current_column_name.to_s),
                          row) # the rest of the members of row are the fact columns
        end
        
        result
      end
    end
  end
end