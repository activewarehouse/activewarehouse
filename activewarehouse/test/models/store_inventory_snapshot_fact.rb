class StoreInventorySnapshotFact < ActiveWarehouse::Fact
  aggregate :quantity_on_hand, :semiadditive => :date, :label => 'Sum Quantity on Hand'
  aggregate :quantity_sold, :label => 'Sum Quantity Sold'
  aggregate :dollar_value_at_cost, :label => 'Sum Dollar Value At Cost'
  aggregate :dollar_value_at_latest_selling_price, :label => 'Sum Value At Latest Price'
  
  calculated_field (:gmroi) do |r| 
    (r.quantity_sold * (r.dollar_value_at_latest_selling_price - r.dollar_value_at_cost)) / 
    (r.quantity_on_hand * r.dollar_value_at_latest_selling_price)
  end
  
  dimension :date
  dimension :store
  dimension :product
end