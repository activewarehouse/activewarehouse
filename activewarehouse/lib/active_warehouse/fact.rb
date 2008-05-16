module ActiveWarehouse #:nodoc

  # Facts represent business measures. A row in a fact table corresponds to set
  # of measurements in a particular
  # granularity along with the foreign keys connecting the fact to various
  # dimensions. All measurements in a fact
  # table must be at the same grain.
  class Fact < ActiveRecord::Base
    class << self
      # Array of AggregateField instances
      attr_accessor :aggregate_fields
      
      # Array of calculated field names
      attr_accessor :calculated_fields
      
      # Hash of calculated field options, where the key is the field name
      # and the value is the Hash of options for that calculated field.
      attr_accessor :calculated_field_options
      
      # Array of belongs_to +Reflection+ instances that represent the
      # dimensions for this fact.
      attr_accessor :dimension_relationships
      
      # Acts as an alias for +belongs_to+, yet marks this relationship
      # as a dimension.  You must call +dimension+ instead of +belongs_to+.
      # Accepts same options as +belongs_to+.
      def dimension(association_id, options = {})
        options[:class_name] ||= "#{association_id}Dimension".classify
        options[:foreign_key] ||= "#{association_id}_id"
        slowly_changing_over = options.delete(:slowly_changing)
        belongs_to association_id, options
        relationship = reflections[association_id]
        
        if slowly_changing_over
          if !dimensions.include?(slowly_changing_over)
            raise "No dimension specified with name '#{slowly_changing_over}' in fact '#{self.name}', specify it first with dimension macro"
          end
          relationship.slowly_changing_over = dimension_relationships[slowly_changing_over]
        end
        
        dimension_relationships[association_id] = relationship
      end

      # Acts as an alias for +has_and_belongs_to_many+, yet marks this relationship
      # as a dimension.  You must call +has_and_belongs_to_many_dimension+ 
      # instead of +has_and_belongs_to_many+.
      # Accepts same options as +has_and_belongs_to_many+.
      def has_and_belongs_to_many_dimension(association_id, options = {})
        options[:class_name] ||= "#{association_id}Dimension".classify
        options[:association_foreign_key] ||= "#{association_id}_id"
        name = self.name.demodulize.chomp('Fact').underscore
        options[:join_table] ||= "#{name}_#{association_id}_bridge"
        has_and_belongs_to_many association_id, options
        relationship = reflections[association_id]
        dimension_relationships[association_id] = relationship
      end
      
      # returns true for the dimension relationship of +belongs_to+
      def belongs_to_relationship?(dimension_name)
        dimension_relationships[dimension_name] and dimension_relationships[dimension_name].macro == :belongs_to  
      end
      
      # returns true for the dimension relationship of +has_and_belongs_to_many+
      def has_and_belongs_to_many_relationship?(dimension_name)
        dimension_relationships[dimension_name] and dimension_relationships[dimension_name].macro == :has_and_belongs_to_many
      end
      
      # returns the AssociationReflection for the specified dimension name
      def dimension_relationship(dimension_name)
        dimension_relationships[dimension_name]
      end

      # returns the dimension name (as specified in the dimension macro)
      # which the specified +dimension_name+ is slowly changing over
      def slowly_changes_over_name(dimension_name)
        dimension_relationships[dimension_name].slowly_changing_over.name
      end
      
      # returns the Class for the dimension which the specified
      # +dimension_name+ is slowly changing over
      def slowly_changes_over_class(dimension_name)
        dimension_class(slowly_changes_over_name(dimension_name))
      end
      
      # Return a list of dimensions for this fact. 
      #
      # Example:
      #
      # sales_fact
      #  date_id
      #  region_id
      #  sales_amount
      #  number_items_sold
      # 
      # Calling SalesFact.dimensions would return the list: [:date, :region]
      def dimensions
        dimension_relationships.collect { |k,v| k }
      end
      
      # Returns the dimension class, given a dimension name from this fact.
      # Must appear as a registered dimension relationship.
      def dimension_class(dimension_name)
        dimension_relationships[dimension_name.to_sym].class_name.constantize
      end
      
      # Get the time when the fact source file was last modified
      def last_modified
        File.new(__FILE__).mtime
      end
      
      # Get the table name. The fact table name is pluralized
      def table_name
        name = self.name.demodulize.underscore.pluralize
        set_table_name(name)
        name
      end
      
      # Get the class name for the specified fact name
      def class_name(name)
        fact_name = name.to_s
        fact_name = "#{fact_name}_facts" unless fact_name =~ /_fact[s?]$/
        fact_name.classify
      end
      
      # Get the class for the specified fact name
      def class_for_name(name)
        class_name(name).constantize
      end
      
      # Get the fact class for the specified value. The fact parameter may be a class,
      # String or Symbol.
      def to_fact(fact_name)
        return fact_name if fact_name.is_a?(Class) and fact_name.superclass == Fact
        return class_for_name(fact_name)
      end
      
      # Return the foreign key that the fact uses to relate back to the specified 
      # dimension. This is found using the dimension_relationships hash.
      def foreign_key_for(dimension_name)
        dimension_relationships[dimension_name].primary_key_name
      end
      
      # Define an aggregate. Also aliased from aggregate()
      # * <tt>field</tt>: The field name
      # * <tt>options</tt>: A hash of options for the aggregate
      def define_aggregate(field, options={})
        if columns_hash[field.to_s].nil?
          raise ArgumentError, "Field #{field} does not exist in table #{table_name}"
        end
        options[:type] ||= :sum
        
        aggregate_field = AggregateField.new(self, columns_hash[field.to_s],
                                             options[:type], options)
        aggregate_fields << aggregate_field
      end
      alias :aggregate :define_aggregate
      
      # Define prejoined fields from a dimension of the fact. Also aliased
      # from prejoin()
      # * <tt>field</tt>: A hash with the key of dimension and an array
      # of attributes from the dimension as value
      def define_prejoin(field)
        prejoined_fields.merge!(field)
      end
      alias :prejoin :define_prejoin
      
      # Define a calculated field
      # * <tt>field</tt>: The field name
      # * <tt>options</tt>: An options hash
      # 
      # This method takes a block which will be passed the current aggregate record.
      #
      # Example: calculated_field (:gross_margin) { |r| r.gross_profit_dollar_amount / r.sales_dollar_amount}
      def calculated_field(field, options={}, &block)
        calculated_fields << CalculatedField.new(self, field, options[:type], options, &block)
      end
      
      # Returns true if this fact has at least one fact that is semiadditive,
      # or false
      def has_semiadditive_fact?
        aggregate_fields.each do |field|
          return true if field.is_semiadditive?
        end
        return false
      end
      
      # Get a list of all calculated fields
      def calculated_fields
        @calculated_field ||= []
      end
      
      # Get the CalculatedField instance for the specified name
      def calculated_field_for_name(name)
        calculated_fields.find {|f| f.name.to_s == name.to_s}
      end
      
      # Get a list of all aggregate fields
      def aggregate_fields
        @aggregate_fields ||= []
      end
      
      # Get the AggregateField instance for the specified name.
      def aggregate_field_for_name(name)
        aggregate_fields.find {|f| f.name.to_s == name.to_s}
      end
      
      # Get the field instance for the specified name. Looks in aggregate fields first, then
      # calculated fields
      def field_for_name(name)
        field = aggregate_fields.find {|f| f.name.to_s == name.to_s}
        field = calculated_fields.find {|f| f.name.to_s == name.to_s} unless field
        field
      end
      
      # The table name to use for the prejoined fact table
      def prejoined_table_name
        "prejoined_#{table_name}"
      end
            
      # Get the hash of all prejoined fields
      def prejoined_fields
        @prejoined_fields ||= {}
      end
      
      def dimension_relationships
        @dimension_relationships ||= OrderedHash.new
      end
      
      def prejoin_fact
        @prejoin_fact ||= ActiveWarehouse::PrejoinFact.new(self)
      end
      
      def populate
        prejoin_fact.populate
      end

    end
  end
end