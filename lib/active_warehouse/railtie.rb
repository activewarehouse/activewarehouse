module ActiveWarehouse
  class Railtie < ::Rails::Railtie
    # Rails-3.0.1 requires config.app_generators instead of 3.0.0's config.generators    
    rake_tasks do
      load "active_warehouse/tasks/active_warehouse.rake"
    end
    
    generators do
      # there are some dependencies between the generators so require order matters
      # we're doing two passes at them
      dependent_files = []
      Dir[File.expand_path('generators/*/*.rb', File.dirname(__FILE__))].each do |file|
        begin
          require file
        rescue # save them to try again
          dependent_files << file
        end
      end
      # second pass
      dependent_files.each do |file|
          require file
      end
    end
  end
end
  