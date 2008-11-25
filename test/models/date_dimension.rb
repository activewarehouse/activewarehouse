class DateDimension < ActiveWarehouse::DateDimension
  define_hierarchy :calendar_year, [:calendar_year, :calendar_month, :day_in_month]
end