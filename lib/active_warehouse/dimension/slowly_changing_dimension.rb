module ActiveWarehouse #:nodoc:
  # Implements Type 2 Slowly Changing Dimensions.
  #
  # In a type 2 SCD, a new row is added each time a dimension entry requires an update. Three columns are required in
  # the dimension table to support this:
  #
  # * latest_version - A boolean flag which indicates whether or not the row is the latest and current value
  # * effective_date - A start date for when this row takes effect
  # * expiration_date - An end date for when this row expires
  #
  # This module will override finder behavior in several ways. If used in a normal fashion, the find method will return
  # the match row or rows with the latest_version flag set to true. You can also call the finder with the :valid_on 
  # option set indicating that you want the row that is valid on the given date.
  #
  # You can completely override the modified finder behavior using the :with_older option (set to true). You *must* include
  # this option if you want to search for records which are not current (for example, using the find(id) version of the finder
  # methods).
  module SlowlyChangingDimension
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Indicate that the dimension is a Type 2 Slowly Changing Dimension (SDC).
      #
      # A word of warning:
      #
      # The expiration_date field must never be null. For the current effective record use the maximum date allowed. 
      # This is necessary because the find query used when :valid_on is specified is implemented using a between clause.
      #
      # Options:
      # * <tt>:identifier</tt>: 
      # * <tt>:lastest_version</tt>: Define the attribute name which represents the latest version flag
      # * <tt>:effective_date</tt>: Define the attribute name which represents the effective date column
      # * <tt>:expiration_date</tt>: Define the attribute name which represents the expiration date column
      #
      def acts_as_slowly_changing_dimension(options = {})

        unless slowly_changing_dimension? # don't let AR call this twice
          cattr_accessor :identifier
          cattr_accessor :latest_version_attribute
          cattr_accessor :effective_date_attribute
          cattr_accessor :expiration_date_attribute
          self.identifier = options[:identifier] || :identifier
          self.latest_version_attribute = options[:with] || :latest_version
          self.effective_date_attribute = options[:effective_date_attribute] || :effective_date
          self.expiration_date_attribute = options[:expiration_date_attribute] || :expiration_date

          #default_scope :conditions =>{self.latest_version_attribute => true}
          
          scope :valid_on, lambda { |valid_on|
            where("? between #{effective_date_attribute} and #{expiration_date_attribute}", valid_on)
          }

          scope :valid_during, lambda { |valid_during|
            where("(? between #{effective_date_attribute} and #{expiration_date_attribute})" +
                  " or (#{effective_date_attribute} between ? and ?)",
                  valid_during.first, valid_during.first, valid_during.last)
          }
          
        end
        
        
        include InstanceMethods
        
      end
      
      # Return true if this dimension is a slowly changing dimension
      def slowly_changing_dimension?
        self.included_modules.include?(InstanceMethods)
      end
      
    end

    module InstanceMethods #:nodoc:
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end
      
      def versions
        self.class.find(:all,
            :conditions => ["#{self.class.identifier} = ?", self.send(identifier)],
            :with_older => true,
            :order => "#{self.class.effective_date_attribute} asc")
      end

      module ClassMethods
        def find_with_older(*args)
          self.unscoped.find(args)
        end

        def count_with_older(*args)
          self.unscoped.count(args)
        end
        
      end # ClassMethods
      
    end
  end
end
