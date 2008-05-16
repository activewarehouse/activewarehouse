module ETL #:nodoc:
  module Transform #:nodoc:
    # Transform a String representation of a date to a Date instance
    class StringToDateTransform < ETL::Transform::Transform
      # Transform the value using Date.parse
      def transform(name, value, row)
        Date.parse(value)
      end
    end
  end
end