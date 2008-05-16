module ActiveWarehouse
  # A Cube represents a collection of dimensions operating on a fact. The Cube
  # provides a front-end for getting at the
  # underlying data. Cubes support pluggable aggregation. The default aggregation
  # is the NoAggregate which goes directly
  # to the fact and dimensions to answer queries.
  class Cube
    class << self
      
      # Callback which is invoked when subclasses are created
      def inherited(subclass)
        subclasses << subclass
      end
      
      # Get a list of all known subclasses
      def subclasses
        @subclasses ||= []
      end
      
      # Defines the dimensions that this cube pivots on. If the fact name and
      # cube name are different (for example, if a PurchaseCube does not report
      # on a PurchaseFact) then you *must* declare the <code>reports_on</code>
      # first.
      def pivots_on(*dimension_list)
        @dimensions_hierarchies = OrderedHash.new
        @dimensions = []
        dimension_list.each do |dimension|
          case dimension
          when Symbol, String
            dimensions << dimension.to_sym
            dimensions_hierarchies[dimension.to_sym] = fact_class.dimension_class(dimension).hierarchies
          when Hash
            dimension_name = dimension.keys.first.to_sym
            dimensions << dimension_name
            dimensions_hierarchies[dimension_name] = [dimension[dimension_name]].flatten
          else
            raise ArgumentError, "Each argument to pivot_on must be a symbol, string or Hash"
          end
        end
      end
      alias :pivot_on :pivots_on
      
      # Defines the fact name, without the 'Fact' suffix, that this cube
      # reports on.  For instance, if you have PurchaseFact, you could then
      # call <code>reports_on :purchase</code>.
      # 
      # The default value for reports_on is to take the name of the cube,
      # i.e. PurchaseCube, and remove the Cube suffix.  The assumption is that
      # your Cube name matches your Fact name.
      def reports_on(fact_name)
        @fact_name = fact_name
      end
      alias :report_on :reports_on
      
      # Rebuild the data warehouse.
      def rebuild(options={})
        populate(options)
      end
      
      # Populate the data warehouse.  Delegate to aggregate.populate
      def populate(options={})
        aggregate.populate
      end
      
      # Get the dimensions that this cube pivots on
      def dimensions
        @dimensions ||= fact_class.dimension_relationships.collect{|k,v| k}
      end
      
      # Get an OrderedHash of each dimension mapped to its hierarchies which 
      # will be included in the cube
      def dimensions_hierarchies
        if @dimensions_hierarchies.nil?
          @dimensions_hierarchies = OrderedHash.new
          dimensions.each do |dimension|
            @dimensions_hierarchies[dimension] = fact_class.dimension_class(dimension).hierarchies
          end
        end
        @dimensions_hierarchies
      end
      
      # returns true if this cube pivots on a hierarchical dimension.
      def pivot_on_hierarchical_dimension?
        dimension_classes.each do |dimension|
          return true if dimension.hierarchical_dimension?
        end
        return false
      end
      
      # returns the aggregate fields for this cube
      # removing the aggregate fields that are defined in fact class that are
      # related to hierarchical dimension, but the cube doesn't pivot on any
      # hierarchical dimensions
      # The method also further removes the not appropreate aggregate fields
      # for the type of dimensions passed in if they exists.
      def aggregate_fields(dims=[])
        agg_fields = fact_class.aggregate_fields.reject {|field| !pivot_on_hierarchical_dimension? and !field.levels_from_parent.empty? } 
        dims.each do |dim|
          if !dim.blank? and fact_class.has_and_belongs_to_many_relationship?(dim.to_sym)
            return agg_fields.reject {|field| !field.is_count_distinct?}
          end
        end
        agg_fields
      end
      
      # Get the class name for the specified cube name
      # Example: Regional Sales will become RegionalSalesCube
      def class_name(name)
        cube_name = name.to_s
        cube_name = "#{cube_name}_cube" unless cube_name =~ /_cube$/
        cube_name.classify
      end
      
      # Get the aggregated fact class name
      def fact_class_name
        ActiveWarehouse::Fact.class_name(@fact_name || name.sub(/Cube$/,'').underscore.to_sym)
      end
      
      # Get the aggregated fact class instance
      def fact_class
        fact_class_name.constantize
      end
      
      # Get a list of dimension class instances
      def dimension_classes
        dimensions.collect do |dimension_name|
          dimension_class(dimension_name)
        end
      end
      
      # Get the dimension class for the specified dimension name
      def dimension_class(dimension_name)
        fact_class.dimension_relationships[dimension_name.to_sym].class_name.constantize      
      end
      
      # Get the cube logger
      def logger
        @logger ||= Logger.new('cube.log')
      end
      
      # Get the time when the fact or any dimension referenced in this cube 
      # was last modified
      def last_modified
        lm = fact_class.last_modified
        dimensions.each do |dimension|
          dim = ActiveWarehouse::Dimension.class_for_name(dimension)
          lm = dim.last_modified if dim.last_modified > lm
        end
        lm
      end
      
      # The temp directory for storing files during warehouse rebuilds
      attr_accessor :temp_dir
      def temp_dir
        @temp_dir ||= '/tmp'
      end
      
      # Specify the ActiveRecord class to connect through
      # Note: this is a potential directive in a Cube subclass
      attr_accessor :connect_through
      def connect_through
        @connect_through ||= ActiveRecord::Base
      end
      
      # Get an adapter connection
      def connection
        connect_through.connection
      end
      
      # Defaults to NoAggregate strategy.
      def aggregate
        @aggregate ||= ActiveWarehouse::Aggregate::NoAggregate.new(self)
      end
      
      def aggregate_class(agg_class)
        @aggregate = agg_class.new(self)
      end
      
    end
    
    public
    # Query the cube. The column dimension, column hierarchy, row dimension and
    # row hierarchy are all required.
    #
    # The conditions value is a String that represents a SQL condition appended
    # to the where clause. TODO: this may eventually be converted to another
    # query language.
    #
    # The cstage value represents the current  column drill down stage and 
    # defaults to 0.
    # 
    # The rstage value represents the current row drill down stage and defaults 
    # to 0. Filters contains key/value pairs where the key is a string of 
    # 'dimension.column' and the value is the value to filter by. For example:
    #
    # filters = {'date.calendar_year' => 2007, 'product.category' => 'Food'}
    # query(:date, :cy, :store, :region, 1, 0, filters)
    #
    # Note that product.category refers to a dimension which is not actually 
    # visible but which is both part of the cube and is used for filtering.
    def query(*args)
      self.class.aggregate.query(*args)
    end
    
    # Get the database connection (delegates to Cube.connection class method)
    def connection
      self.class.connection
    end
    
  end
  
end