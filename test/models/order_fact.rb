class OrderFact < ActiveWarehouse::Fact
  aggregate :total_amount
  dimension :store
  dimension :date
end