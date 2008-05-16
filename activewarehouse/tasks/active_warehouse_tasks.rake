namespace :warehouse do 
  desc "Drop and create the current database"
  task :recreate => :environment do
    abcs = ActiveRecord::Base.configurations
    ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
    puts "Recreating #{ActiveRecord::Base.connection.current_database}"
    ActiveRecord::Base.connection.recreate_database(ActiveRecord::Base.connection.current_database)
    ActiveRecord::Base.connection.reconnect!
  end
  
  desc "Build a 'standard' date dimension"
  task :build_date_dimension => :environment do
    abcs = ActiveRecord::Base.configurations
    ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])

    start_date = (ENV['START_DATE'] ? Time.parse(ENV['START_DATE']) : Time.now.years_ago(5))
    end_date = (ENV['END_DATE'] ? Time.parse(ENV['END_DATE']) : Time.now )
    
    if ENV['TRUNCATE']
      puts "Truncating date dimension"
      DateDimension.connection.execute("TRUNCATE TABLE date_dimension")
    end
    
    puts "Building date dimension"

    ddb = ActiveWarehouse::Builder::DateDimensionBuilder.new(start_date, end_date)
    ddb.build.each do |record|
      dd = DateDimension.new
      record.each do |key,value|
        dd.send("#{key}=".to_sym, value) if dd.respond_to?(key)
      end
      dd.save!
    end
  end
  
  desc "Build random data for all facts and dimensions in the models directory, excluding date"
  task :build_random_data => :environment do
    abcs = ActiveRecord::Base.configurations
    ActiveRecord::Base.establish_connection(abcs[RAILS_ENV])
    require 'pp'
    
    name = ENV['NAME']
    options = {}
    options[:truncate] = true if ENV['TRUNCATE']
    options[:facts] = ENV['FACTS'].to_i if ENV['FACTS']
    options[:dimensions] = ENV['DIMENSIONS'].to_i if ENV['DIMENSIONS']
    
    if name
      build_and_load(name, options)
    else
      models_dir = File.join(File.dirname(__FILE__), '../../../../app/models')
      Dir.glob(File.join(models_dir, "**", "*_dimension.rb")).each do |f|
        name = File.basename(f, '.rb')
        next if name == 'date_dimension'
        options[:rows] = options[:dimensions]
        build_and_load(name, options)
      end
      Dir.glob(File.join(models_dir, "**", "*_fact.rb")).each do |f|
        name = File.basename(f, '.rb')
        options[:rows] = options[:facts]
        build_and_load(name, options)
      end
    end
  end
  
  desc "Populate with test data"
  task :populate => [:build_date_dimension, :build_random_data]
  
  desc "Recreate, migrate and populate"
  task :setup => [:recreate, :migrate, 'db:migrate', :populate]
  
  desc "Rebuild the warehouse" # TODO: consider moving this logic somewhere into a class and calling it from here
  task :rebuild => :environment do
    puts "Rebuilding data warehouse"
    # Discover and require all cube models
    # TODO: do some more research on the potential problems with this
    models_dir = File.join(File.dirname(__FILE__), '../../../../app/models')
    Dir.glob(File.join(models_dir, "**", "*.rb")).each do |f|
      if f =~ /_cube\.rb/
        require f
      end
    end
    
    t = Benchmark.realtime do 
      ActiveWarehouse::Cube.subclasses.each do |subclass|
        puts "Rebuilding #{subclass}"
        tc = Benchmark.realtime do
          subclass.populate(:force => true)
        end
        puts "Rebuilt #{subclass} in #{tc}s"
      end
    end
    puts "Data warehouse rebuilt in #{t}s"
  end
  
  desc "Migrate ActiveWarehouse"
  task :migrate => :environment do
    puts "Migrating ActiveWarehouse"
    migration_directory = File.join(File.dirname(__FILE__), '../db/migrations')
    ActiveWarehouse::Migrator.migrate(migration_directory, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end
end

def build_and_load(name, options)
  builder = ActiveWarehouse::Builder::RandomDataBuilder.new
  
  clazz = name.classify.constantize
  if options[:truncate] # TODO: Handle through adapter by adding a truncate method to the adapter
    puts "Truncating #{name}"
    clazz.connection.execute("TRUNCATE TABLE #{clazz.table_name}")
  end
  
  options[:fk_limit] = {}
  options[:fk_limit]['date_id'] = DateDimension.count
  
  puts "Building #{name}"
  builder.build(name, options).each do |record|
    clazz.create(record)
  end
rescue => e
  puts "Unable to build #{name}: #{e}"
end