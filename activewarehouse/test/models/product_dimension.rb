class ProductDimension < ActiveWarehouse::Dimension
  acts_as_slowly_changing_dimension
  define_hierarchy :brand, [:brand_description]
end