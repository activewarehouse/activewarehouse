class RollupSalesTransactionsCube < ActiveWarehouse::Cube
  aggregate_class ActiveWarehouse::Aggregate::PipelinedRolapAggregate, {:truncate=>false, :new_records_only=>{:dimension => :date}}

  reports_on :pos_retail_sales_transaction

  pivots_on({:date=>:rollup}, {:store=>:region}, {:product=>:product_id})
end
