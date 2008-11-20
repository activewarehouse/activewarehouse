module ActiveWarehouse #:nodoc:
  # Bridge class that models ragged hierarchies.
  class HierarchyBridge < Bridge
    class << self
      def set_levels_from_parent(name)
        @levels_from_parent = name
      end
     
      def levels_from_parent
        @levels_from_parent ||= "levels_from_parent"
      end
     
      def set_effective_date(name)
        @effective_date = name
      end
     
      def effective_date
        @effective_date ||= "effective_date"
      end
     
      def set_expiration_date(name)
        @expiration_date = name
      end
     
      def expiration_date
        @expiration_date ||= "expiration_date"
      end
     
      def set_top_flag(name)
        @top_flag = name
      end
     
      def top_flag
        @top_flag ||= "top_flag"
      end
     
      def set_top_flag_value(value)
        @top_flag_value = value
      end
     
      def top_flag_value
        @top_flag_value ||= 'Y'
      end 
    end
  end
end