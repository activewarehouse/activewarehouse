module ActiveWarehouse
  class Railtie < ::Rails::Railtie
    # Rails-3.0.1 requires config.app_generators instead of 3.0.0's config.generators    
    rake_tasks do
      load "active_warehouse/tasks/active_warehouse.rake"
  end
end
  