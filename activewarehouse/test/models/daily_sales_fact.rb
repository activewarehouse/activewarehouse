class DailySalesFact < ActiveWarehouse::Fact
  aggregate :cost
  aggregate :id, :type => :count, :distinct => true, :label => 'Num Sales'

  dimension :date
  dimension :store
  has_and_belongs_to_many_dimension :product, 
    :join_table => 'sales_products_bridge', :foreign_key => 'sale_id'
end