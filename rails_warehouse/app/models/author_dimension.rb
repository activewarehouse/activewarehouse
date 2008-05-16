class AuthorDimension < ActiveWarehouse::Dimension
  define_hierarchy :name, [:name]
end