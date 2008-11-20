module ActiveWarehouse #:nodoc:
  module Builder #:nodoc:
    # Build random data usable for testing.
    class RandomDataBuilder
      # Hash of generators where the key is the class and the value is an
      # implementation of AbstractGenerator
      attr_reader :generators
      
      # Hash of names mapped to generators where the name is the column name
      attr_reader :column_generators
      
      # Initialize the random data builder
      def initialize
        @generators = {
          Fixnum => FixnumGenerator.new,
          Float => FloatGenerator.new,
          Date => DateGenerator.new,
          Time => TimeGenerator.new,
          String => StringGenerator.new,
          Object => BooleanGenerator.new,
        }
        @column_generators = {}
      end
      
      # Build the data for the specified class. Name may be a Class (which must
      # descend from ActiveWarehouse::Dimension
      # or ActiveWarehouse::Fact), a String or a Symbol. String or Symbol will
      # be converted to a class name and then 
      # passed back to this method.
      def build(name, options={})
        case name
        when Class
          if name.respond_to?(:base_class)
            return build_dimension(name, options) if name.base_class == ActiveWarehouse::Dimension
            return build_fact(name, options) if name.base_class == ActiveWarehouse::Fact
          end
          raise "#{name} is a class but does not appear to descend from Fact or Dimension"
        when String
          begin
            build(name.classify.constantize, options)
          rescue NameError
            raise "Cannot find a class named #{name.classify}"
          end
        when Symbol
          build(name.to_s, options)
        else
          raise "Unable to determine what to build"
        end
      end
      
      # Build test dimension data for the specified dimension name.
      #
      # Options:
      #
      # * <tt>:rows</tt>: The number of rows to create (defaults to 100)
      # * <tt>:generators</tt>: A map of generators where each key is Fixnum,
      #   Float, Date, Time, String, or Object and the
      #   value is extends from AbstractGenerator. 
      def build_dimension(name, options={})
        options[:rows] ||= 100
        options[:generators] ||= {}
        rows = []

        dimension_class = Dimension.to_dimension(name)
        options[:rows].times do
          row = {}
          dimension_class.content_columns.each do |column|
            generator = (options[:generators][column.klass] ||
                         @column_generators[column.name] ||
                         @generators[column.klass])
            if generator.nil?
              raise ArgumentError, "No generator found, unknown column type?: #{column.klass}"
            end
            row[column.name] = generator.generate(column, options)
          end
          rows << row
        end
        
        rows
      end
      
      # Build test fact data for the specified fact name
      # 
      # Options:
      # * <tt>:rows</tt>: The number of rows to create (defaults to 100)
      # * <tt>:generators</tt>: A Hash of generators where each key is Fixnum,
      #   Float, Date, Time, String, or Object and the
      #   value is extends from AbstractGenerator.
      # * <tt>:fk_limit</tt>: A Hash of foreign key limits, where each key is
      #   the name of column and the value is 
      #   a number. For example options[:fk_limit][:date_id] = 1000 would limit
      #   the foreign key values to something between
      #   1 and 1000, inclusive.
      # * <tt>:dimensions</tt>: The number of available dimension FKs
      def build_fact(name, options={})
        options[:rows] ||= 100
        options[:generators] ||= {}
        options[:fk_limit] ||= {}
        rows = []

        fact_class = Fact.to_fact(name)
        options[:rows].times do
          row = {}
          fact_class.content_columns.each do |column|
            generator = (options[:generators][column.klass] || @generators[column.klass])
            row[column.name] = generator.generate(column, options)
          end
          fact_class.dimension_relationships.each do |name, reflection|
            # it would be better to get a count of rows from the dimension tables
            fk_limit = (options[:fk_limit][reflection.primary_key_name] ||
                        options[:dimensions] || 100) - 1
            row[reflection.primary_key_name] = rand(fk_limit) + 1
          end
          rows << row
        end
        
        rows
      end
    end
    
    # Implement this class to provide an generator implementation for a specific class.
    class AbstractGenerator
      # Generate the next value. The column parameter must be an
      # ActiveRecord::Adapter::Column instance. 
      # The options hash is implementation dependent.
      def generate(column, options={})
        raise "generate method must be implemented by a subclass"
      end
    end
    
    # Basic Date generator
    class DateGenerator < AbstractGenerator
      # Generate a random date value
      #
      # Options:
      # * <tt>:start_date</tt>: The start date as a Date or Time object
      #   (default 1 year ago)
      # * <tt>:end_date</tt>: The end date as a Date or Time object (default now)
      def generate(column, options={})
        end_date = (options[:end_date] || Time.now).to_date
        start_date = (options[:start_date] || 1.year.ago).to_date
        number_of_days = end_date - start_date
        start_date + rand(number_of_days)
      end
    end
    
    # Basic Time generator
    #
    # Options:
    # * <tt>:start_date</tt>: The start date as a Date or Time object
    # (default 1 year ago)
    # * <tt>:end_date</tt>: The end date as a Date or Time object (default now)
    class TimeGenerator < DateGenerator #:nodoc:
      # Generate a random Time value
      def generate(column, options={})
        super(column, options).to_time
      end
    end
    
    # Basic Fixnum generator
    class FixnumGenerator
      # Generate an integer from 0 to options[:max] inclusive
      #
      # Options:
      # * <tt>:max</tt>: The maximum allowed value (default 1000)
      # * <tt>:min</tt>: The minimum allowed value (default 0)
      def generate(column, options={})
        options[:max] ||= 1000
        options[:min] ||= 0
        rand(options[:max] + (-options[:min])) - options[:min]
      end
    end
    
    # Basic Float generator
    class FloatGenerator
      # Generate a float from 0 to options[:max] inclusive (default 1000)
      #
      # Options:
      # * <tt>:max</tt>: The maximum allowed value (default 1000)
      def generate(column, options={})
        options[:max] ||= 1000
        rand * options[:max].to_f
      end
    end
    
    # Basic BigDecimal generator
    class BigDecimalGenerator
      # Generate a big decimal from 0 to options[:max] inclusive (default 1000)
      #
      # Options:
      # * <tt>:max</tt>: The maximum allowed value (default 1000)
      def generate(column, options={})
        options[:max] ||= 1000
        BigDecimal.new((rand * options[:max].to_f).to_s) # TODO: need BigDecimal type?
      end
    end
    
    # A basic String generator
    class StringGenerator
      # Initialize the StringGenerator.
      #
      # Options:
      # * <tt>:values</tt>: List of possible values
      # * <tt>:chars</tt>: List of chars to use to generate random values
      def initialize(options={})
        @options = options
      end
      # Generate a random string
      #
      # Options:
      # * <tt>:values</tt>: An array of values to use. If not specified then
      #   random char values will be used.
      # * <tt>:chars</tt>: An array of characters to use to generate random
      #   values (default [a..zA..Z])
      def generate(column, options={})
        options[:values] ||= @options[:values]
        options[:chars] ||= @options[:chars]
        if options[:values]
          options[:values][rand(options[:values].length)]
        else
          s = ''
          chars = (options[:chars] || ('a'..'z').to_a + ('A'..'Z').to_a)
          0.upto(column.limit - 1) do |n|
            s << chars[rand(chars.length)]
          end
          s
        end
      end
    end
    
    # A basic Boolean generator
    class BooleanGenerator
      # Generate a random boolean
      def generate(column, options={})
        rand(1) == 1
      end
    end
  end
end