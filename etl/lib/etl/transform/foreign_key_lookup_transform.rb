module ETL #:nodoc:
  module Transform #:nodoc:
    # Transform which looks up the value and replaces it with a foriegn key reference
    class ForeignKeyLookupTransform < ETL::Transform::Transform
      # The resolver to use if the foreign key is not found in the collection
      attr_accessor :resolver
      
      # Initialize the foreign key lookup transform.
      #
      # Configuration options:
      # *<tt>:collection</tt>: A Hash of natural keys mapped to surrogate keys. If this is not specified then
      #  an empty Hash will be used. This Hash will be used to cache values that have been resolved already
      #  for future use.
      # *<tt>:resolver</tt>: Object or Class which implements the method resolve(value)
      def initialize(control, name, configuration={})
        super
        
        @collection = (configuration[:collection] || {})
        @resolver = configuration[:resolver]
        @resolver = @resolver.new if @resolver.is_a?(Class)
      end
      
      # Transform the value by resolving it to a foriegn key
      def transform(name, value, row)
        fk = @collection[value]
        unless fk
          raise ResolverError, "Foreign key for #{value} not found and no resolver specified" unless resolver
          raise ResolverError, "Resolver does not appear to respond to resolve method" unless resolver.respond_to?(:resolve)
          fk = resolver.resolve(value)
          raise ResolverError, "Unable to resolve #{value} to foreign key for #{name} in row #{ETL::Engine.rows_read}" unless fk
          @collection[value] = fk
        end
        fk
      end
    end
    # Alias class name for the ForeignKeyLookupTransform.
    class FkLookupTransform < ForeignKeyLookupTransform; end
  end
end

# Resolver which resolves using ActiveRecord.
class ActiveRecordResolver
  # The ActiveRecord class to use
  attr_accessor :ar_class
  
  # The find method to use (as a symbol)
  attr_accessor :find_method
  
  # Initialize the resolver. The ar_class argument should extend from 
  # ActiveRecord::Base. The find_method argument must be a symbol for the 
  # finder method used. For example:
  # 
  # ActiveRecordResolver.new(Person, :find_by_name)
  #
  # Note that the find method defined must only take a single argument.
  def initialize(ar_class, find_method)
    @ar_class = ar_class
    @find_method = find_method
  end
  
  # Resolve the value
  def resolve(value)
    rec = ar_class.__send__(find_method, value)
    rec.nil? ? nil : rec.id
  end
end

class SQLResolver
  # Initialize the SQL resolver. Use the given table and field name to search
  # for the appropriate foreign key. The field should be the name of a natural
  # key that is used to locate the surrogate key for the record.
  #
  # The connection argument is optional. If specified it can be either a symbol
  # referencing a connection defined in the ETL database.yml file or an actual
  # ActiveRecord connection instance. If the connection is not specified then
  # the ActiveRecord::Base.connection will be used.
  def initialize(table, field, connection=nil)
    @table = table
    @field = field
    @connection = (connection.respond_to?(:quote) ? connection : ETL::Engine.connection(connection)) if connection
    @connection ||= ActiveRecord::Base.connection
  end
  def resolve(value)
    @connection.select_value("SELECT id FROM #{table_name} WHERE #{@field} = #{@connection.quote(value)}")
  end
  def table_name
    ETL::Engine.table(@table, @connection)
  end
end