module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    class ChartReport < ActiveRecord::Base #:nodoc:
      include AbstractReport
      before_save :to_storage
      after_save :from_storage
    end
  end
end