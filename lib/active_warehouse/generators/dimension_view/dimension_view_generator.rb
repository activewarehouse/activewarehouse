module ActiveWarehouse
  class DimensionViewGenerator < Rails::Generators::NamedBase
    attr_accessor :file_name, :view_name, :query_target_name, :query_target_table_name, :view_query, :view_attributes
  
    include Rails::Generators::Migration

    self.source_root(File.expand_path("../templates", __FILE__))

    argument :name, :type => :string, :required => true, :banner => 'DimensionViewName'
    argument :target_table, :type => :string, :required => true, :banner => 'TargetTable'
    class_option :skip_migration, :desc => 'Don\'t generate migration file for dimension view.', :type => :boolean
    check_class_collision
    check_class_collision :suffix => "Test"
  
    def initialize(*args, &block)
      super
      puts args
      
    
      @name = @name.tableize.singularize
      @query_target_name = args[1]
      # define the view and query target table name
      @view_name = "#{@name}_dimension"
      @query_target_table_name = "#{query_target_name}_dimension"
      # define the view class name and query target class name
      @class_name = "#{view_name.camelize}"
      @query_target_class_name = "#{query_target_table_name.camelize}"
      # define the output file name
      @file_name = "#{class_name.tableize.singularize}"
      # define the query target class and expose its columns as attributes for the view
      @query_target_class = @query_target_class_name.constantize
      @view_attributes = @query_target_class.column_names
      @view_query = "select #{@view_attributes.join(',')} from #{query_target_table_name}"
    end
  
     # Implement the required interface for Rails::Generators::Migration.
     # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
     def self.next_migration_number(dirname)
       if ActiveRecord::Base.timestamped_migrations
         Time.now.utc.strftime("%Y%m%d%H%M%S")
       else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    def create_migration_file
      unless options[:skip_migration]
        migration_template 'migration.rb', "db/migrate/create_#{file_name.gsub(/\//, '_').pluralize}.rb"
      end
    end

    def create_files
      template 'model.rb', "app/models/#{file_name}.rb"
      template 'unit_test.rb',"test/unit/#{file_name}_test.rb"
      template 'fixture.yml', "test/fixtures/#{table_name}.yml"
    end
  
    def banner
      "Usage: #{$0} #{spec.name} #{spec.name.camelize}Name SelectTarget [options]"
    end
  
  end
end