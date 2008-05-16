class FileDimension < ActiveWarehouse::Dimension
  define_hierarchy :file, [:directory, :path]
  define_hierarchy :file_type, [:file_type, :path]
end