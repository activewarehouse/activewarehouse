module ActiveWarehouse #:nodoc:
  # A field that uses a Proc to calculate the value 
  class CalculatedField < Field
    attr_reader :block
    # Initialize the calculated field
    #
    # +fact_class+ is the fact class that the field is calculated in
    # +name+ is the name of the calculated field
    # +type+ is the type of the calculated field (defaults to :integer)
    # +field_options+ is a Hash of options for the field
    # 
    # This method accepts a block which should take a single argument that is the record
    # itself.
    def initialize(fact_class, name, type = :integer, field_options = {}, &block)
      unless block_given?
        raise ArgumentError, "A block is required for the calculated field #{name} in #{fact_class}"
      end
      super(fact_class, name.to_s, type, field_options)
      @block = block
    end
    
    # Calculate the field value using the Hash of type-casted values
    def calculate(values)
      @block.call(values)
    end
  end
end