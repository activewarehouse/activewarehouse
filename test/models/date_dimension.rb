class DateDimension < ActiveWarehouse::DateDimension
  set_order :id
  define_hierarchy :cy, [:calendar_year, :calendar_quarter, :calendar_month_name, :calendar_week, :day_of_week]
  define_hierarchy :fy, [:fiscal_year, :fiscal_quarter, :calendar_month_name, :fiscal_week, :day_of_week]
  define_hierarchy :rollup, [:calendar_year, :calendar_month_number_in_year, :calendar_week_start_date, :sql_date_stamp]
end