class SalespersonSalesFact < ActiveWarehouse::Fact
  aggregate :cost
  aggregate :cost, :type => :count, :label => 'Num Sales'
  
  dimension :date
  dimension :salesperson, :slowly_changing => :date
  dimension :product
end