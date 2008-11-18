class RegionalSalesCube < ActiveWarehouse::Cube
  reports_on :pos_retail_sales_transaction
  pivots_on({:date => :cy}, :store)
end