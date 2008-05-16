Dir[File.dirname(__FILE__) + "/generator/*.rb"].each { |file| require(file) }

module ActiveWarehouse #:nodoc:
  module Builder #:nodoc:
    # Unlike the RandomDataBuilder, which puts truly random data in the warehouse, this 
    # generator uses collections of possible values to construct semi-understandable data
    class TestDataBuilder
      def initialize
        
      end
      
      # Usage: 
      #
      #   fields = [:id,:product_name,:product_description,:suggested_retail_price]
      #   field_definitions = {
      #     :id => :sequence,                                                  # symbol or string
      #     :product_name => [['Foo','Bar']['Baz','Bing']],                    # array
      #     :product_description => IpsumLorumGenerator                        # class
      #     :suggested_retail_price => RandomNumberGenerator.new(0.00, 100.00) # generator instance
      #   }
      def build(fields, field_definitions, options={})
        options[:number] ||= 100
        rows = []
        generators = {}
        # set up all of the generators first
        field_definitions.each do |name, fd|
          case fd
          when Class
            generators[name] = fd.new
          when String, Symbol
            generators[name] = "#{fd}Generator".classify.constantize.new
          when Array
            generators[name] = NameGenerator.new(fd)
          when Generator
            generators[name] = fd
          else
            raise "Invalid generator specified: #{fd}"
          end
        end
        
        # generate all of the rows
        0.upto(options[:number]) do
          row = {}
          fields.each do |field|
            row[field] = generators[field].next(options)
          end
          rows << row
        end
        
        rows
      end
    end
  end
end