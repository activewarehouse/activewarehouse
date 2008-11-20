class SalespersonDimension < ActiveWarehouse::Dimension
  acts_as_hierarchical_dimension
  acts_as_slowly_changing_dimension
  define_hierarchy :name, [:name]
  define_hierarchy :region, [:region, :sub_region]
  child_bridge :child_bridge
  parent_bridge :parent_bridge
end