class FileRevisionFact < ActiveWarehouse::Fact
  aggregate :file_changed, :label => "File Changed"
  
  dimension :date
  dimension :file
  dimension :change_type
  dimension :author
end