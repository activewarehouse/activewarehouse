module ActiveWarehouse
  # Explicit date dimension, because Date dimension has special columns
  # which can be configured to have different names.
  class DateDimension < Dimension
    class << self
      def set_sql_date_stamp(name)
        @sql_date_stamp = name
      end
      
      def sql_date_stamp
        @sql_date_stamp ||= "sql_date_stamp"
      end
    end
  end
end