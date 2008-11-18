ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  drop_table :store_dimension
  create_table :store_dimension do |t|
    t.string :store_region, :null => false
    t.string :store_state, :null => false
  end 
end