class BridgeGenerator < Rails::Generator::NamedBase
  attr_accessor :file_name
  
  default_options :skip_migration => false
  
  def initialize(runtime_args, runtime_options = {})
    super
    
    @name = @name.tableize.singularize
    @table_name = "#{@name}_bridge"
    @class_name = "#{@name.camelize}Bridge"
    @file_name = "#{@class_name.tableize.singularize}"
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
      m.template 'fixture.yml', File.join('test/fixtures', class_path, "#{table_name}.yml")
      
      # Generate the migration unless :skip_migration option is specified
      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_name.gsub(/\//, '_')}"
      end
    end
  end
  
  protected
    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-migration", 
             "Don't generate a migration file for this bridge") { |v| options[:skip_migration] = v }
    end
end