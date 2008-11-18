class StoreDimension < ActiveWarehouse::Dimension
  define_hierarchy :location, [:store_state, :store_county, :store_city]
  define_hierarchy :region, [:store_region, :store_district]
end