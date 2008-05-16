module ETL #:nodoc:
  module Execution #:nodoc
    # Handles migration of tables required for persistent storage of meta data 
    # for the ETL engine
    class Migration
      class << self
        # Execute the migrations
        def migrate
          connection.initialize_schema_information
          v = connection.select_value("SELECT version FROM #{schema_info_table_name}").to_i
          v.upto(target - 1) do |i| 
            __send__("migration_#{i+1}".to_sym)
            update_schema_info(i+1)
          end
        end
        protected
        # Get the schema info table name
        def schema_info_table_name
          ETL::Execution::Base.table_name_prefix + "schema_info" + 
            ETL::Execution::Base.table_name_suffix
        end
        
        # Get the connection to use during migration
        def connection
          @connection ||= ETL::Execution::Base.connection
        end
        
        # Get the final target version number
        def target
          3
        end
        
        private
        def migration_1 #:nodoc:
          connection.create_table :jobs do |t|
            t.column :control_file, :string, :null => false
            t.column :created_at, :datetime, :null => false
            t.column :completed_at, :datetime
            t.column :status, :string
          end
          connection.create_table :records do |t|
            t.column :control_file, :string, :null => false
            t.column :natural_key, :string, :null => false
            t.column :crc, :string, :null => false
            t.column :job_id, :integer, :null => false
          end
        end
        
        def migration_2 #:nodoc:
          connection.add_index :records, :control_file
          connection.add_index :records, :natural_key
          connection.add_index :records, :job_id
        end
        
        def migration_3 #:nodoc:
          connection.create_table :batches do |t|
            t.column :batch_file, :string, :null => false
            t.column :created_at, :datetime, :null => false
            t.column :completed_at, :datetime
            t.column :status, :string
          end
          connection.add_column :jobs, :batch_id, :integer
          connection.add_index :jobs, :batch_id
        end
      
        # Update the schema info table, setting the version value
        def update_schema_info(version)
          connection.update("UPDATE #{schema_info_table_name} SET version = #{version}")
        end
      end
    end
  end
end
