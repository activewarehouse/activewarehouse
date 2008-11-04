module ActiveWarehouse #:nodoc
  # DimensionViews represent role-playing dimensions in a data warehouse. 
  # These types of dimensions provide a view for an existing dimension. A 
  # common use is to provide a date dimension and then provide numerous
  # role-playing dimensions implemented as views to the date dimension, 
  # such as Order Date Dimension, Shipping Date Dimension, etc.
  class DimensionView < Dimension
    class << self
      def set_order(name)
        super("#{self.sym}_#{name}".to_sym)
      end
      def define_hierarchy(name, hierarchy)
        super(name, hierarchy.collect { |name| "#{self.sym}_#{name}".to_sym })
      end
    end
    def method_missing(method_name, *args)
      unless method_name.to_s =~ /^#{self.class.sym}_/
        method_name = "#{self.class.sym}_#{method_name}".to_sym
      end
      if attribute_present?(method_name)
        read_attribute(method_name)
      else
        raise NameError, "Attribute #{method_name} not found in #{self.class}"
      end
    end
  end
end