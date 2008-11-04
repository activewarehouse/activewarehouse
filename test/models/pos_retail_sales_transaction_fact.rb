class PosRetailSalesTransactionFact < ActiveWarehouse::Fact

  aggregate :sales_quantity, :label => 'Sum of Sales Quantity'
  aggregate :sales_quantity, :label => 'Sum of Sales Quantity Self', :levels_from_parent => [0]
  aggregate :sales_quantity, :label => 'Sum of Sales Quantity Me and Immediate children', :levels_from_parent => [:self, 1]
  aggregate :sales_dollar_amount, :label => 'Sum of Sales Amount'
  aggregate :cost_dollar_amount, :label => 'Sum of Cost'
  aggregate :gross_profit_dollar_amount, :label => 'Sum of Gross Profit'
  aggregate :sales_quantity, :type => :count, :label => 'Sales Quantity Count'
  aggregate :sales_dollar_amount, :type => :avg, :label => 'Avg Sales Amount'
  
  calculated_field (:gross_margin) { |r| r.gross_profit_dollar_amount / r.sales_dollar_amount}
  
  dimension :date
  dimension :store
  dimension :product
  dimension :promotion
  dimension :customer
  
  prejoin :product => [:category_description, :brand_description]
  prejoin :promotion => [:promotion_name]
end
