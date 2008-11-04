module ActiveWarehouse #:nodoc:
  # Class that holds the results of a Cube query
  class CubeQueryResult
    attr_reader :aggregate_fields_hash
  
    # Initialize the aggregate map with an array of AggregateField instances.
    # The AggregateFields are used to typecast the raw values coming from
    # the database.  Thank you very little, DBI.
    def initialize(aggregate_fields)
      raise ArgumentError, "aggregate_fields must not be empty" unless aggregate_fields && aggregate_fields.size > 0
      @aggregate_fields_hash = {}
      aggregate_fields.each {|c| @aggregate_fields_hash[c.label] = c}
      @values_map = {}
    end

    # Return true if the aggregate map includes the specified row value
    def has_row_values?(row_value)
      @values_map.has_key?(row_value.to_s)
    end
    
    # iterate through every row and column combination
    def each
      @values_map.each do |key, value|
        yield key, value
      end
    end
  
    def value(row_value, col_value, field_label)
      #puts "getting value #{row_value},#{col_value},#{field_label}"
      values(row_value, col_value)[field_label]
    end
  
    # returns a hash of type casted fact values for the intersection of
    # row_value and col_value
    def values(row_value, col_value)
      row = @values_map[row_value.to_s]
      return empty_hash_for_missing_row_or_column if row.nil?
      facts = row[col_value.to_s]
      return empty_hash_for_missing_row_or_column if facts.nil?
      facts
    end
  
    # Add a hash of aggregated facts for the given row and column values.
    # For instance, add_data('Southeast', 2005, {:sales_sum => 40000, :sales_count => 40})
    # This method will typecast the values in aggregated_facts.
    def add_data(row_value, col_value, aggregated_facts)
      #puts "Adding data for #{row_value}, #{col_value} [data=[#{aggregated_facts.join(',')}]]"
      @values_map[row_value.to_s] ||= {}
      @values_map[row_value.to_s][col_value.to_s] = typecast_facts(aggregated_facts)
    end
    
    private
    def empty_hash_for_missing_row_or_column
      empty = {}
      aggregate_fields_hash.keys.each {|k| empty[k] = 0}
      empty
    end
    
    def typecast_facts(raw_facts)
      raw_facts.each do |k,v|
        field = aggregate_fields_hash[k]
        if field.nil?
          raise ArgumentError, "'#{k}' is an unknown aggregate field in this query result"
        end
        raw_facts[k] = field.type_cast(v)
      end
    end
  end
end