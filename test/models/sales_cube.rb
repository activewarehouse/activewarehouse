class SalesCube < ActiveWarehouse::Cube
  reports_on :order
end