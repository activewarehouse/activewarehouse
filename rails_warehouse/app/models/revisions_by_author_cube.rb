class RevisionsByAuthorCube < ActiveWarehouse::Cube
  reports_on :file_revision
  pivots_on :date, :author, :change_type, :file
end