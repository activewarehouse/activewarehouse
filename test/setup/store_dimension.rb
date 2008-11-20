fields = {
  :store_name => :string,
  :store_number => :string,
  :store_street_address => :string,
  :store_city => :string,
  :store_county => :string,
  :store_state => :string,
  :store_zip_code => :string,
  :store_manager => :string,
  :store_district => :string,
  :store_region => :string,
  :floor_plan_type => :string,
  :photo_processing_type => :string,
  :financial_service_type => :string,
  :selling_square_footage => :integer,
  :total_square_footage => :integer,
  :first_open_date => :integer, # FK with view on date_dimension
  :last_remodal_date => :integer, # FK with view on date_dimension
}
ActiveRecord::Base.connection.create_table :store_dimension, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end