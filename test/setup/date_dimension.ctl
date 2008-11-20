require File.dirname(__FILE__) + '/../../lib/active_warehouse'

table = 'date_dimension'
pre_process :truncate, :target => :awunit, :table => table

ddb = ActiveWarehouse::Builder::DateDimensionBuilder.new(Time.gm(2001, "jan", 1), Time.gm(2008, "dec", 31))

source :in, {
  :type => :enumerable,
  :enumerable => ddb.build,
  :store_locally => false
}, 
[ 
  :date,
  :full_date_description,
  :day_of_week,
  {:name => :day_number_in_epoch, :type => :integer},
  {:name => :week_number_in_epoch, :type => :integer},
  {:name => :month_number_in_epoch, :type => :integer},
  {:name => :day_number_in_calendar_month, :type => :integer},
  {:name => :day_number_in_calendar_year, :type => :integer},
  {:name => :day_number_in_fiscal_month, :type => :integer},
  {:name => :day_number_in_fiscal_year, :type => :integer},
  :last_day_in_week_indicator,
  :last_day_in_month_indicator,
  :calendar_week,
  :calendar_week_ending_date,
  {:name => :calendar_week_number_in_year, :type => :integer},
  :calendar_month_name,
  {:name => :calendar_month_number_in_year, :type => :integer},
  :calendar_year_month,
  :calendar_quarter,
  :calendar_year_quarter,
  :calendar_half_year,
  :calendar_year,
  :fiscal_week,
  {:name => :fiscal_week_number_in_year, :type => :integer},
  :fiscal_year_month,
  :fiscal_quarter,
  :fiscal_year_quarter,
  :fiscal_half_year,
  :fiscal_year,
  :holiday_indicator,
  :weekday_indicator,
  :selling_season,
  :major_event,
  :sql_date_stamp,
]

transform(:sql_date_stamp){|n,v,r| v.to_s(:db) }

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0