dimension = 'promotion_dimension'
pre_process :truncate, :target => :awunit, :table => dimension

source :in, {
  :file => "#{dimension}.csv",
  :parser => :delimited,
  :store_locally => false
}, 
[ 
  :promotion_name,
  :price_reduction_type,
  :promotion_media_type,
  :ad_type,
  :display_type,
  :coupon_type,
  :ad_media_name,
  :display_provider,
  :promotion_cost,
  {:name => :promotion_begin_date, :type => :date}, # TODO: FK with date_dimension view
  {:name => :promotion_end_date, :type => :date}, # TODO: FK with date_dimension view
]

transform :promotion_cost, :type, :type => :integer

destination :out, :type => :database, :target => :awunit, :table => dimension, :buffer_size => 0