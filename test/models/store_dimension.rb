class StoreDimension < ActiveWarehouse::Dimension
  define_hierarchy :location, [:store_region, :store_state, :store_county]
end