class DateDimension < ActiveWarehouse::Dimension
  set_order :sql_date_stamp
  define_hierarchy :cy, [:calendar_year,:calendar_quarter,:calendar_month_name]
end