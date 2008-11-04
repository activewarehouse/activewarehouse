class CustomerSalesCube < ActiveWarehouse::Cube
  reports_on :pos_retail_sales_transaction
  pivots_on({:date => :cy}, {:customer => :customer_name})
end