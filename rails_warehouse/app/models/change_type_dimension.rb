class ChangeTypeDimension < ActiveWarehouse::Dimension
  define_hierarchy :change_type, [:change_type_description]
end