module ActiveWarehouse #:nodoc:
  # Responsible for migrating ActiveWarehouse tables which are automatically created.
  class Migrator < ActiveRecord::Migrator
    class << self
      def schema_info_table_name #:nodoc:
        ActiveRecord::Base.table_name_prefix + 'activewarehouse_schema_info' + ActiveRecord::Base.table_name_suffix
      end
      
      def current_version #:nodoc:
        result = ActiveRecord::Base.connection.select_one("SELECT version FROM #{schema_info_table_name}")
        if result
          result['version'].to_i
        else
          # There probably isn't an entry for this plugin in the migration info table.
          # We need to create that entry, and set the version to 0
          ActiveRecord::Base.connection.execute("INSERT INTO #{schema_info_table_name} (version) VALUES (0)")      
          0
        end
      end    
    end
    
    def set_schema_version(version)
      ActiveRecord::Base.connection.update("UPDATE #{self.class.schema_info_table_name} SET version = #{down? ? version.to_i - 1 : version.to_i}")
    end
  end
end

module ActiveRecord #:nodoc:
  module ConnectionAdapters #:nodoc:
    module SchemaStatements #:nodoc:
      def initialize_schema_information_with_activewarehouse
        initialize_schema_information_without_activewarehouse
        
        begin
          execute "CREATE TABLE #{ActiveWarehouse::Migrator.schema_info_table_name} (version #{type_to_sql(:integer)})"
        rescue ActiveRecord::StatementInvalid
          # Schema has been initialized
        end
      end
      alias_method_chain :initialize_schema_information, :activewarehouse
      
      def dump_schema_information_with_activewarehouse
        schema_information = []
        
        dump = dump_schema_information_without_activewarehouse
        schema_information << dump if dump
        
        begin
          plugins = ActiveRecord::Base.connection.select_all("SELECT * FROM #{ActiveWarehouse::Migrator.schema_info_table_name}")
          plugins.each do |plugin|
            if (version = plugin['version'].to_i) > 0
              schema_information << "INSERT INTO #{ActiveWarehouse::Migrator.schema_info_table_name} (version) VALUES (#{version})"
            end
          end
        rescue ActiveRecord::StatementInvalid 
          # No Schema Info
        end
        
        schema_information.join("\n")
      end
      alias_method_chain :dump_schema_information, :activewarehouse
    end
  end
end