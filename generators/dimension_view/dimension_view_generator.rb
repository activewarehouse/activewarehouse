class DimensionViewGenerator < Rails::Generator::NamedBase
  attr_accessor :file_name, :view_name, :query_target_name, :query_target_table_name, :view_query, :view_attributes
  
  default_options :skip_migration => false
  
  def initialize(runtime_args, runtime_options = {})
    super
    
    usage if runtime_args.length != 2
    
    @name = @name.tableize.singularize
    @query_target_name = runtime_args[1]
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
  
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, "#{class_name}", "#{class_name}Test"
      
      # Create required directories if necessary
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      m.directory File.join('test/fixtures', class_path)
      
      # Generate the files
      m.template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")
      #m.template 'fixture.yml', File.join('test/fixtures', class_path, "#{table_name}.yml")
      
      # Generate the migration unless :skip_migration option is specified
      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_name.gsub(/\//, '_')}"
      end
    end
  end
  
  def banner
    "Usage: #{$0} #{spec.name} #{spec.name.camelize}Name SelectTarget [options]"
  end
  
  protected
    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-migration", 
             "Don't generate a migration file for this dimension view") { |v| options[:skip_migration] = v }
    end
end