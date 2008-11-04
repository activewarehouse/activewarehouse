module ActiveWarehouse #:nodoc
  # Implements a bridge table.
  class Bridge < ActiveRecord::Base
    class << self
      # Get the table name. By default the table name will be the name of the
      # bridge in singular form.
      #
      # Example: DepartmentHierarchyBridge will have a table called
      # department_hierarchy_bridge
      def table_name
        name = self.name.demodulize.underscore
        set_table_name(name)
        name
      end
    end
  end
end

require 'active_warehouse/bridge/hierarchy_bridge'