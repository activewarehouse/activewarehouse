class CustomerDimension < ActiveWarehouse::Dimension
  acts_as_hierarchical_dimension
  define_hierarchy :customer_name, [:customer_name]
  child_bridge :child_bridge
  parent_bridge :parent_bridge
end