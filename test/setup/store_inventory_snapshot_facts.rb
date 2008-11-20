fields = {
  :date_id => :integer,
  :product_id => :integer,
  :store_id => :integer,
  :quantity_on_hand => :integer,
  :quantity_sold => :integer,
  :dollar_value_at_cost => :decimal,
  :dollar_value_at_latest_selling_price => :decimal
}
conn = ActiveRecord::Base.connection
conn.create_table :store_inventory_snapshot_facts, :force => true do |t|
  fields.each do |name,type|
    if type == :decimal
      t.column name, type, :scale => 2, :precision => 18
    else
      t.column name, type
    end
  end
end