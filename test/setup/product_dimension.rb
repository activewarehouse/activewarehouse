fields = {
  :product_description => :string,
  :sku_number => :string,
  :brand_description => :string,
  :category_description => :string,
  :department_description => :string,
  :package_type_description => :string,
  :package_size => :string,
  :fat_content => :string,
  :diet_type => :string,
  :weight => :integer,
  :weight_units_of_measure => :string,
  :storage_type => :string,
  :shelf_life_type => :string,
  :shelf_width => :string,
  :shelf_height => :string,
  :shelf_depth => :string,
  :latest_version => :boolean,
  :effective_date => :datetime,
  :expiration_date => :datetime
}
ActiveRecord::Base.connection.create_table :product_dimension, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end