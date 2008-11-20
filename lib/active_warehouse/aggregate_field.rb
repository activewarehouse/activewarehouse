module ActiveWarehouse
  # Encapsulates a fact column in a fact table.  These fields
  # represent columns that should be aggregated.
  class AggregateField < Field
  
    attr_reader :strategy_name
    
    # +fact_class+ is the class of the fact table this field is found in.
    # +column_definition+ is the ActiveRecord ColumnDefinition instance for this
    # column.
    # +strategy_name+ is the name of th aggregation strategy to be used, defaults to :sum
    # +field_options+ is a hash of raw options from the original aggregate definition.
    def initialize(fact_class, column_definition, strategy_name = :sum, field_options = {})
      super(fact_class, column_definition.name, column_definition.type, field_options)
      @column_definition = column_definition
      @limit = column_definition.limit
      @scale = column_definition.scale
      @precision = column_definition.precision
      @strategy_name = strategy_name
    end
    
    # delegates to owning_class, returns the Fact that has this field
    def fact_class
      owning_class
    end
    
    # Returns true if the field is semi-additive
    def is_semiadditive?
      !field_options[:semiadditive].nil?
    end
    
    def is_distinct?
      field_options[:distinct] and field_options[:distinct] == true
    end
    
    def is_count_distinct?
      @strategy_name == :count and is_distinct?
    end
    
    # returns the Dimension that this semiadditive fact is over
    def semiadditive_over
      Dimension.to_dimension(field_options[:semiadditive])
    end
    
    # overrides Field.label, prepending the aggregation strategy name to label
    def label
      @label ? @label : "#{super}_#{strategy_name}"
    end
    
    def levels_from_parent
      field_options[:levels_from_parent].nil? ? [] : field_options[:levels_from_parent]
    end
    
    # Typecast the specified value using the column definition
    def type_cast(value)
      @column_definition.type_cast(value)
    end
  end
end