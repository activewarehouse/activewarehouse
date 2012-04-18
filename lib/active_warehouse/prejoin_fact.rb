module ActiveWarehouse #:nodoc:
  # Class that supports prejoining a fact table with dimensions. This is useful if you need
  # to list facts along with some or all of their detail information.
  class PrejoinFact
    # The fact class that this engine instance is connected to
    attr_accessor :fact_class
    
    delegate :prejoined_table_name, 
      :connection, 
      :prejoined_fields,
      :dimension_relationships, 
      :dimension_class, 
      :table_name,
      :columns, :to => :fact_class
  
    # Initialize the engine instance
    def initialize(fact_class)
      @fact_class = fact_class
    end
  
    # Populate the prejoined fact table.
    def populate(options={})
      populate_prejoined_fact_table(options)
    end
    
    protected
    # Drop the storage table
    def drop_prejoin_fact_table
      connection.drop_table(prejoined_table_name) if connection.tables.include?(prejoined_table_name)
    end
    
    # Get foreign key names that are excluded.
    def excluded_foreign_key_names
      excluded_dimension_relations = prejoined_fields.keys.collect {|k| dimension_relationships[k]}
      excluded_dimension_relations.collect {|r| r.foreign_key}
    end
    
    # Construct the prejoined fact table.
    def create_prejoined_fact_table(options={})
      connection.transaction {
        drop_prejoin_fact_table

        connection.create_table(prejoined_table_name, :id => false) do |t|
          # get all columns except the foreign_key columns for prejoined dimensions
          columns.each do |c|
            t.column(c.name, c.type) unless excluded_foreign_key_names.include?(c.name)
          end
          #prejoined_columns
          prejoined_fields.each_pair do |key, value|
            dclass = dimension_class(key)
            dclass.columns.each do |c|
              t.column(c.name, c.type) if value.include?(c.name.to_sym) 
            end
          end
        end
      }
    end
    
    # Populate the prejoined fact table.
    def populate_prejoined_fact_table(options={})
      fact_columns_string = columns.collect {|c|
        "#{table_name}." + c.name unless excluded_foreign_key_names.include?(c.name)
      }.compact.join(",\n")  
      
      prejoined_columns = []
      
      tables_and_joins = "#{table_name}"
      
      prejoined_fields.each_pair do |key, value|
        dimension = dimension_class(key)
        tables_and_joins += "\nJOIN #{dimension.table_name} as #{key}"
        tables_and_joins += "\n  ON #{table_name}.#{dimension_relationships[key].foreign_key} = "
        tables_and_joins += "#{key}.#{dimension.primary_key}"
        prejoined_columns << value.collect {|v| "#{key}." + v.to_s}
      end

      if connection.support_select_into_table?
        drop_prejoin_fact_table
        sql = <<-SQL
          SELECT #{fact_columns_string}, 
            #{prejoined_columns.join(",\n")}
          FROM #{tables_and_joins}
        SQL
        sql = connection.add_select_into_table(prejoined_table_name, sql)
      else
        create_prejoined_fact_table(options)
        sql = <<-SQL
          INSERT INTO #{prejoined_table_name}
          SELECT #{fact_columns_string}, 
            #{prejoined_columns.join(",\n")}
          FROM #{tables_and_joins}
        SQL
      end
      connection.transaction { connection.execute(sql) }                
    end
  end
end
