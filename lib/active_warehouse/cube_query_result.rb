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
      aggregate_fields.each {|c| @aggregate_fields_hash[c.label.to_s] = c}
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

    def row(row_value)
      @values_map[row_value.to_s] || {}
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
      #puts "Adding data for #{row_value}, #{col_value} [data=[#{aggregated_facts.inspect}]]"
      row_value = "Totals" if row_value.blank?
      col_value = "Totals" if col_value.blank?
      @values_map[row_value.to_s] ||= {}
      @values_map[row_value.to_s][col_value.to_s] = typecast_facts(aggregated_facts)
    end

    # def to_json
    #   json_data = {}
    #   @values_map.keys.each do |row_value|
    #     puts "found row: #{row_value}"
    #     json_data[row_value] = {}
    #     row = @values_map[row_value]
    #     row.keys.each do |column_value|
    #       puts "found value: #{column_value}"
    #       # json_data[row_value][column_value] =  {"test" => 1}
    #       aggregate_values = row[column_value]
    #       json_data[row_value][column_value] =  Hash[aggregate_values.map{|k, v| [aggregate_fields_hash[k].name, v] }]
    #     end
    #   end
    #   json_data.to_json
    # end

    private

    def empty_hash_for_missing_row_or_column
      empty = {}
      aggregate_fields_hash.keys.each {|k| empty[k] = 0}
      empty
    end

    def typecast_facts(raw_facts)

      raw_facts.each do |k,v|
        field = aggregate_fields_hash[k.to_s]
        if field.nil?
          raise ArgumentError, "'#{k}' is an unknown aggregate field in this query result"
        end
        raw_facts[k] = type_cast_aggregate_value(v, field) unless field.nil?
      end
    end

    def type_cast_aggregate_value(value, field)
      if value.is_a?(String) || value.nil?
        operation = field.strategy_name.to_s
        case operation

          # count must be an integer
        when 'count'  then value.to_i

          # sum could be a decimal or integer
        when 'sum'    then ([:decimal, :float].include?(field.type) ? (value.try(:to_d) || 0) : value.to_i)

          # avg should be a decimal, as it involves division
        when 'avg'    then (value.try(:to_d) || 0)

          # max and min and others keep field type
        else field.type_cast(value)
        end
      else
        value
      end
    end

  end
end
