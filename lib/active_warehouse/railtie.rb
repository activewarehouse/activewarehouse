module ActiveWarehouse
  class Railtie < ::Rails::Railtie
    # Rails-3.0.1 requires config.app_generators instead of 3.0.0's config.generators    
    rake_tasks do
      load "active_warehouse/tasks/active_warehouse.rake"
    end
    
    puts Dir[File.expand_path('*.rb', File.dirname(__FILE__))]
    
    generators do
      Dir[File.expand_path('*.rb', File.dirname(__FILE__))].each do |file|
        require file
      end
    end
  end
end
  