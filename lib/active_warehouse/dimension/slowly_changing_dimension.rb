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
          class << self
            alias_method :find_every_with_older,    :find_every
            alias_method :calculate_with_older,     :calculate
            alias_method :core_validate_find_options, :validate_find_options
            VALID_FIND_OPTIONS << :with_older
            VALID_FIND_OPTIONS << :valid_on
            VALID_FIND_OPTIONS << :valid_during
          end
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
          options = extract_options_from_args!(args)
          validate_find_options(options)
          set_readonly_option!(options)
          options[:with_older] = true # yuck!

          case args.first
            when :first then find_initial(options)
            when :all   then find_every(options)
            else             find_from_ids(args, options)
          end
        end

        def count_with_older(*args)
          calculate_with_older(:count, *construct_count_options_from_legacy_args(*args))
        end

        def count(*args)
          with_older_scope { count_with_older(*args) }
        end

        def calculate(*args)
          with_older_scope { calculate_with_older(*args) }
        end

        protected
          def with_older_scope(&block)
            with_scope({:find => { :conditions =>
                  ["#{table_name}.#{latest_version_attribute} = ?", true] } }, :merge, &block)
          end
          
          def with_valid_on_scope(valid_on, &block)
            with_scope({:find => { :conditions =>
                  ["? between #{effective_date_attribute} " +
                  "and #{expiration_date_attribute}", valid_on]} }, :merge, &block)
          end
          
          def with_valid_during_scope(valid_during, &block)
            with_scope({:find => {:conditions =>
                  ["(? between #{effective_date_attribute} and #{expiration_date_attribute})" +
                  " or (#{effective_date_attribute} between ? and ?)",
                  valid_during.first, valid_during.first, valid_during.last]} }, :merge, &block)
          end

        private
          # all find calls lead here
          def find_every(options)
            if options.include?(:valid_on)
              with_valid_on_scope(options[:valid_on]) { find_every_with_older(options) }
            elsif options.include?(:valid_during)
              if !options.include?(:order)
                options[:order] = "#{effective_date_attribute} asc"
              end
              if !options.include?(:limit)
                options[:limit] = 1
              end
              if !options.include?(:offset)
                options[:offset] = 0
              end
              with_valid_during_scope(options[:valid_during]) { find_every_with_older(options) }
            elsif options.include?(:with_older)
              find_every_with_older(options)
            else
              with_older_scope { find_every_with_older(options) }
            end
          end
      end
    end
  end
end