require 'zlib'

module ETL #:nodoc:
  module Control #:nodoc:
    # Base class for destinations.
    class Destination
      # Read-only accessor for the ETL::Control::Control instance
      attr_reader :control
      
      # Read-only accessor for the configuration Hash
      attr_reader :configuration
      
      # Read-only accessor for the destination mapping Hash
      attr_reader :mapping
      
      # Accessor to the buffer size
      attr_accessor :buffer_size
      
      # Unique flag.
      attr_accessor :unique
      
      # A condition for writing
      attr_accessor :condition
      
      # An array of rows to append to the destination
      attr_accessor :append_rows
      
      class << self
        # Get the destination class for the specified name.
        # 
        # For example if name is :database or 'database' then the 
        # DatabaseDestination class is returned
        def class_for_name(name)
          ETL::Control.const_get("#{name.to_s.camelize}Destination")
        end
      end
      
      # Initialize the destination
      #
      # Arguments:
      # * <tt>control</tt>: The ETL::Control::Control instance
      # * <tt>configuration</tt>: The configuration Hash
      # * <tt>mapping</tt>: The mapping Hash
      #
      # Options:
      # * <tt>:buffer_size</tt>: The output buffer size (default 1000 records)
      # * <tt>:condition</tt>: A conditional proc that must return true for the 
      #   row to be written
      # * <tt>:append_rows</tt>: An array of rows to append
      def initialize(control, configuration, mapping)
        @control = control
        @configuration = configuration
        @mapping = mapping
        @buffer_size = configuration[:buffer_size] ||= 100
        @condition = configuration[:condition]
        @append_rows = configuration[:append_rows]
      end
      
      # Get the current row number
      def current_row
        @current_row ||= 1
      end
      
      # Write the given row
      def write(row)
        if @condition.nil? || @condition.call(row)
          process_change(row)
        end
        flush if buffer.length >= buffer_size
      end
      
      # Abstract method
      def flush
        raise NotImplementedError, "flush method must be implemented by subclasses"
      end
      
      # Abstract method
      def close
        raise NotImplementedError, "close method must be implemented by subclasses"
      end
      
      def errors
        @errors ||= []
      end
      
      protected
      # Access the buffer
      def buffer
        @buffer ||= []
      end
      
      # Access the generators map
      def generators
        @generators ||= {}
      end
      
      # Get the order of elements from the source order
      def order_from_source
        order = []
        control.sources.first.definition.each do |item|
          case item
          when Hash
            order << item[:name]
          else
            order << item
          end
        end
        order
      end
      
      # Return true if the row is allowed. The row will not be allowed if the
      # :unique option is specified in the configuration and the compound key 
      # already exists
      def row_allowed?(row)
        if unique
          key = (unique.collect { |k| row[k] }).join('|')
          return false if compound_key_constraints[key]
          compound_key_constraints[key] = 1
        end
        return true
      end
      
      # Get a hash of compound key contraints. This is used to determine if a
      # row can be written when the unique option is specified
      def compound_key_constraints
        @compound_key_constraints ||= {}
      end
      
      # Return fields which are Slowly Changing Dimension fields. 
      # Uses the scd_fields specified in the configuration.  If that's
      # missing, uses all of the row's fields.
      def scd_fields(row)
        # The caching is critical here - it ensures that row.keys is only 
        # called once.  That means we always get the fields in the same order.
        # Since these values will be used to calculate a CRC, it's important
        # that they always come in the same order.
        @scd_fields ||= configuration[:scd_fields] || row.keys
      end
      
      def non_scd_fields(row)
        @non_csd_fields ||= row.keys - natural_key - scd_fields(row) - [primary_key, scd_effective_date_field, scd_end_date_field]
      end
      
      def scd?
        !configuration[:scd].nil?
      end
      
      def scd_type
        scd? ? configuration[:scd][:type] : nil
      end
      
      # Get the Slowly Changing Dimension effective date field. Defaults to
      # 'effective_date'.
      def scd_effective_date_field
        configuration[:scd][:effective_date_field] || :effective_date if scd?
      end
      
      # Get the Slowly Changing Dimension end date field. Defaults to 
      # 'end_date'.
      def scd_end_date_field
        configuration[:scd][:end_date_field] || :end_date if scd?
      end
      
      # Return the natural key field names, defaults to []
      def natural_key
        @natural_key ||= determine_natural_key
      end
      
      # Get the dimension table if specified
      def dimension_table
        ETL::Engine.table(configuration[:scd][:dimension_table], dimension_target) if scd?
      end
      
      # Get the dimension target if specified
      def dimension_target
        configuration[:scd][:dimension_target] if scd?
      end
      
      # Process a row to determine the change type
      def process_change(row)
        ETL::Engine.logger.debug "Processing row: #{row.inspect}"
        return unless row
        
        # Change processing can only occur if the natural key exists in the row 
        ETL::Engine.logger.debug "Checking for natural key existence"
        unless has_natural_key?(row)
          buffer << row
          return
        end
        
        @timestamp = Time.now

        # See if the crc for the current row (and scd_fields) matches
        # the last ETL::Execution::Record with the same natural key.
        # If they match then throw away this row (no need to process).
        # If they do not match then the record is an 'update'. If the
        # record doesn't exist then it is an 'insert'        
        ETL::Engine.logger.debug "Checking record for CRC change"
        if last_crc = last_recorded_crc_for_row(row)
          if last_crc != crc_for_row(row)
            process_crc_change(row)
            save_crc(row)
          else
            process_crc_match(row)
          end
        else
          process_no_crc(row)
          save_crc(row)
        end
      end
      
      # Add any virtual fields to the row. Virtual rows will get their value 
      # from one of the following:
      # * If the mapping is a Class, then an object which implements the next 
      #   method
      # * If the mapping is a Symbol, then the XGenerator where X is the 
      #   classified symbol
      # * If the mapping is a Proc, then it will be called with the row
      # * Otherwise the value itself will be assigned to the field
      def add_virtuals!(row)
        if mapping[:virtual]
          mapping[:virtual].each do |key,value|
            # If the row already has the virtual set, assume that's correct
            next if row[key]
            # Engine.logger.debug "Mapping virtual #{key}/#{value} for row #{row}"
            case value
            when Class
              generator = generators[key] ||= value.new
              row[key] = generator.next
            when Symbol
              generator = generators[key] ||= ETL::Generator::Generator.class_for_name(value).new(options)
              row[key] = generator.next
            when Proc
              row[key] = value.call(row)
            else
              if value.is_a?(ETL::Generator::Generator)
                row[key] = value.next
              else
                row[key] = value
              end
            end
          end
        end
      end
      
      private
      
      # Determine the natural key. This method will always return an array
      # of symbols. The default value is [].
      def determine_natural_key
        Array(configuration[:natural_key]).collect(&:to_sym)
      end
      
      # Check whether a natural key has been defined, and if so, whether
      # this row has enough information to do searches based on that natural
      # key.
      # 
      # TODO: This should be factored out into
      # ETL::Row#has_all_fields?(field_array) But that's not possible
      # until *all* sources cast to ETL::Row, instead of sometimes
      # using Hash
      def has_natural_key?(row)
        natural_key.any? && natural_key.all? { |key| row.has_key?(key) }
      end
      
      # Calculates a CRC for the given row.  Only uses the scd_fields,
      # if provided.  Defaults to doing a crc on all the field's
      # values.
      def crc_for_row(row)
        s = scd_fields(row).inject("") { |str, field| str + row[field].to_s }
        Zlib.crc32(s).to_s
      end
      
      # Helper for turning an array of natural key values into a
      # single value.  Used by CRC recorder.  Example: If the table's
      # natural key is first_name, last_name, and a specific user's is
      # {:first_name => "Joe", :last_name => "Smith", :birth_date =>
      # 3.years.ago} this helper will return "Joe|Smith"
      def joined_natural_key_for_row(row)
        natural_key.collect{|k|row[k].to_s}.join('|')
      end
      
      # Looks up the CRC recorded from the last time there was a change
      def last_recorded_crc_for_row(row)
        crc_record = ETL::Execution::Record.find_by_control_file_and_natural_key(control.file, joined_natural_key_for_row(row))
        
        crc_record ? crc_record.crc : nil
      end
      
      # Helper for generating the SQL where clause that allows searching
      # by a natural key
      def natural_key_equality_for_row(row)
        statement = []
        values = []
        natural_key.each do |nk|
          statement << "#{nk} = ?"
          values << row[nk]
        end
        statement = statement.join(" AND ")
        ActiveRecord::Base.send(:sanitize_sql, [statement, *values])
      end
      
      # Do all the steps required when a CRC *has* changed.  Exact steps
      # depend on what type of SCD we're handling.
      def process_crc_change(row)
        ETL::Engine.logger.debug "CRC does not match"
        
        if scd_type == 2
          # SCD Type 2: new row should be added and old row should be updated
          ETL::Engine.logger.debug "type 2 SCD"
          
          if original_record = preexisting_row(row)
            # To update the old row, we delete the version in the database
            # and insert a new expired version
            
            # If there is no truncate then the row will exist twice in the database
            delete_outdated_record(original_record)
            
            ETL::Engine.logger.debug "expiring original record"
            original_record[scd_end_date_field] = @timestamp
            
            buffer << original_record
          end

        elsif scd_type == 1
          # SCD Type 1: only the new row should be added
          ETL::Engine.logger.debug "type 1 SCD"

          if original_record = preexisting_row(row)
            # Copy primary key over from original version of record
            row[primary_key] = original_record[primary_key]
            
            # If there is no truncate then the row will exist twice in the database
            delete_outdated_record(original_record)
          end
        else
          # SCD Type 3: not supported
          ETL::Engine.logger.debug "SCD type #{scd_type} not supported"
        end
        
        # In all cases, the latest, greatest version of the record
        # should go into the load
        schedule_new_record(row)
      end
      
      # Do all the steps required when a CRC has *not* changed.  Exact
      # steps depend on what type of SCD we're handling.
      def process_crc_match(row)
        ETL::Engine.logger.debug "CRC matches"
        
        if original_record = preexisting_row(row)
          if scd_type == 2 && has_non_scd_field_changes?(row, original_record)
            # Copy primary key over from original version of record
            row[primary_key] = original_record[primary_key]

            # If there is no truncate then the row will exist twice in the database
            delete_outdated_record(original_record)
            
            buffer << row
          else
            # The record is totally the same, so skip it
          end
        else
          # The record never made it into the database, so add the effective and end date
          # and add it into the bulk load file
          schedule_new_record(row)
        end
      end
      
      # Do all steps required when a pre-existing CRC couldn't be
      # found.  Exact steps depend on what type of SCD we're handling.
      def process_no_crc(row)
        ETL::Engine.logger.debug "CRC missing - record never loaded"
        
        schedule_new_record(row)
      end
      
      # Find the version of this row that already exists in the datawarehouse.
      def preexisting_row(row)
        raise ConfigurationError, "dimension_table setting required" unless dimension_table
        
        q = "SELECT * FROM #{dimension_table} WHERE #{natural_key_equality_for_row(row)}"
        q << " ORDER BY #{scd_end_date_field} DESC" if scd_type == 2
        
        #puts "looking for original record"
        result = connection.select_one(q)
        
        #puts "Result: #{result.inspect}"
        
        result ? ETL::Row[result.symbolize_keys!] : nil
      end
      
      # Check whether non-scd fields have changed since the last
      # load of this record.
      def has_non_scd_field_changes?(row, original_record)
        non_scd_fields(row).any? { |non_csd_field| row[non_csd_field] != original_record[non_csd_field] }
      end
      
      # Grab, or re-use, a database connection for running queries directly
      # during the destination processing.
      def connection
        return @conn if @conn
        
        raise ConfigurationError, "dimension_target setting required" unless dimension_target
        
        @conn = ETL::Engine.connection(dimension_target)
      end
      
      # Utility for removing a row that has outdated information.  Note
      # that this deletes directly from the database, even if this is a file
      # destination.  It needs to do this because you can't do deletes in a 
      # bulk load.
      def delete_outdated_record(original_record)
        ETL::Engine.logger.debug "deleting old row"
        
        q = "DELETE FROM #{dimension_table} WHERE #{primary_key} = #{original_record[primary_key]}"
        connection.delete(q)
      end
      
      # Schedule the latest, greatest version of the row for insertion
      # into the database
      def schedule_new_record(row)
        ETL::Engine.logger.debug "writing new record"
        if scd_type == 2
          row[scd_effective_date_field] = @timestamp
          row[scd_end_date_field] = '9999-12-31 00:00:00'
        end
        buffer << row
      end
      
      # Get the name of the primary key for this table.  Asks the dimension
      # model class for this information, but if that class hasn't been 
      # defined, just defaults to :id.
      def primary_key
        return @primary_key if @primary_key
        @primary_key = dimension_table.to_s.camelize.constantize.primary_key.to_sym
      rescue NameError => e
        ETL::Engine.logger.debug "couldn't get primary_key from dimension model class, using default :id"
        @primary_key = :id
      end
      
      # Save a CRC representation of the row's values.  This can be looked
      # up later, to see if the row has changed.
      def save_crc(row)
        # Record the record
        if ETL::Engine.job # only record the execution if there is a job
          ETL::Execution::Record.time_spent += Benchmark.realtime do
            ETL::Execution::Record.create!(
              :control_file => control.file,
              :natural_key => joined_natural_key_for_row(row),
              :crc => crc_for_row(row),
              :job_id => ETL::Engine.job.id
            )
          end
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/destination/*.rb"].each { |file| require(file) }