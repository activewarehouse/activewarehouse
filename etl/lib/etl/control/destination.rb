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
      
      # Return fields which are Slowly Changing Dimension fields. Return nil 
      # by default.
      def scd_fields
        @scd_fields ||= configuration[:scd_fields]
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
      
      # Return the natural key field name, defaults to :id
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
        if natural_key.length == 0
          buffer << row
          return
        end
        
        natural_key.each do |key| 
          unless row.has_key?(key)
            buffer << row
            return
          end
        end
        
        ETL::Engine.logger.debug "Checking for SCD fields"
        s = String.new
        if scd_fields
          scd_fields.each { |f| s << row[f].to_s }
        else
          row.each { |key,value| s << value.to_s }
        end
      
        # apply the CRC to 's' and see if it matches the last 
        # ETL::Execution::Record with the samenatural key. If they match then 
        # throw away this row (no need to process). If they do not match then 
        # the record is an 'update'. If the record doesn't exist then it is an
        # 'insert'
        nk = natural_key.collect{|k|row[k]}.join('|')
        require 'zlib'
        crc = Zlib.crc32(s)
        record = ETL::Execution::Record.find_by_control_file_and_natural_key(control.file, nk)
        
        timestamp = Time.now
        
        ETL::Engine.logger.debug "Checking record change type"
        if record
          if record.crc != crc.to_s
            # SCD Type 1: only the new row should be added
            # SCD Type 2: both an old and new row should be added
            # SCD Type 3: not supported
            ETL::Engine.logger.debug "CRC does not match"
            
            if scd_type == 2
              ETL::Engine.logger.debug "type 2 SCD"
              
              raise ConfigurationError, "dimension_table setting required" unless dimension_table
              raise ConfigurationError, "dimension_target setting required" unless dimension_target
              
              conn = ETL::Engine.connection(dimension_target)
              
              q = "SELECT * FROM #{dimension_table} WHERE "
              q << natural_key.collect { |nk| "#{nk} = '#{row[nk]}'" }.join(" AND ")
              #puts "looking for original record"
              result = conn.select_one(q)
              if result
                #puts "Result: #{result.inspect}"
                original_record = ETL::Row[result.symbolize_keys!]
                original_record[scd_end_date_field] = timestamp
                ETL::Engine.logger.debug "writing original record"
                
                # if there is no truncate then the row will exist twice in the database
                # need to figure out how to delete that old record before inserting the
                # updated version of the record
                
                q = "DELETE FROM #{dimension_table} WHERE "
                q << natural_key.collect { |nk| "#{nk} = '#{row[nk]}'" }.join(" AND ")
                
                num_rows_affected = conn.delete(q)
                ETL::Engine.logger.debug "deleted old row"
                
                # do this?
                #raise "Should have deleted a single record" if num_rows_affected != 1
                
                buffer << original_record
              end
              
              row[scd_effective_date_field] = timestamp
              row[scd_end_date_field] = '9999-12-31 00:00:00'
            elsif scd_type == 1
              ETL::Engine.logger.debug "type 1 SCD"
            else
              ETL::Engine.logger.debug "SCD not specified"
            end
            
            ETL::Engine.logger.debug "writing new record"
            buffer << row
          else
            ETL::Engine.logger.debug "CRC matches, skipping"
            
            raise ConfigurationError, "dimension_table setting required" unless dimension_table
            raise ConfigurationError, "dimension_target setting required" unless dimension_target
            
            conn = ETL::Engine.connection(dimension_target)
            
            q = "SELECT * FROM #{dimension_table} WHERE "
            q << natural_key.collect { |nk| "#{nk} = '#{row[nk]}'" }.join(" AND ")
            result = conn.select_one(q)
            if result
              # This was necessary when truncating and then loading, however I
              # am getting reluctant to having the ETL process do the truncation
              # as part of the bulk load, favoring using a preprocessor instead.
              # buffer << ETL::Row[result.symbolize_keys!]
            else
              # The record never made it into the database, so add the effective and end date
              # and add it into the bulk load file
              row[scd_effective_date_field] = timestamp
              row[scd_end_date_field] = '9999-12-31 00:00:00'
              buffer << row
            end
          end
        else
          ETL::Engine.logger.debug "record never loaded"
          # Set the effective and end date fields
          if scd_type == 2
            row[scd_effective_date_field] = timestamp
            row[scd_end_date_field] = '9999-12-31 00:00:00'
          end
          
          # Write the row
          buffer << row
          
          # Record the record
          if ETL::Engine.job # only record the execution if there is a job
            ETL::Execution::Record.time_spent += Benchmark.realtime do
              ETL::Execution::Record.create!(
                :control_file => control.file,
                :natural_key => nk,
                :crc => crc,
                :job_id => ETL::Engine.job.id
              )
            end
          end
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
      # of symbols. The default value is [:id].
      def determine_natural_key
        case configuration[:natural_key]
        when Array
          configuration[:natural_key].collect(&:to_sym)
        when String, Symbol
          [configuration[:natural_key].to_sym]
        else
          [] # no natural key defined
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/destination/*.rb"].each { |file| require(file) }