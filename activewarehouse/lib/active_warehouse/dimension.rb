# require all of the "acts_as" mixins first
require 'active_warehouse/dimension/hierarchical_dimension'
require 'active_warehouse/dimension/slowly_changing_dimension'
require 'active_warehouse/dimension/dimension_reflection'

ActiveRecord::Reflection::AssociationReflection.send(:include, ActiveWarehouse::DimensionReflection)

module ActiveWarehouse #:nodoc
  # Dimension tables contain the textual descriptors of the business. Dimensions
  # provide the filters which  are applied to facts. Dimensions are the primary
  # source of query constraints, groupings and report labels.
  class Dimension < ActiveRecord::Base
    include ActiveWarehouse::HierarchicalDimension
    include ActiveWarehouse::SlowlyChangingDimension
    
    after_save :expire_value_tree_cache
    
    class << self
      # Alternate order by, to be used rather than the current level being queried
      attr_accessor :order
      
      # Map of level names to alternate order columns
      attr_reader :level_orders
      
      # Define a column to order by. If this value is specified then it will be
      # used rather than the actual level being queried in the following method
      # calls:
      # * available_values
      # * available_child_values
      # * available_values_tree
      def set_order(name)
        @order = name
      end
      
      # Define a column to order by for a specific level.
      def set_level_order(level, name)
        level_orders[level] = name
      end
      
      # Get the level orders map
      def level_orders
        @level_orders ||= {}
      end
      
      # Define a named attribute hierarchy in the dimension.
      # 
      # Example: define_hierarchy(:fiscal_calendar, [:fiscal_year, :fiscal_quarter, :fiscal_month])
      # 
      # This would indicate that one of the drill down paths for this dimension is:
      # Fiscal Year -> Fiscal Quarter -> Fiscal Month
      #
      # Internally the hierarchies are stored in order. The first hierarchy
      # defined will be used as the default if no hierarchy is specified when
      # rendering a cube.
      def define_hierarchy(name, levels)
        hierarchies << name
        hierarchy_levels[name] = levels
      end
      
      # Get the named attribute hierarchy. Returns an array of column names.
      # 
      # Example: hierarchy(:fiscal_calendar) might return [:fiscal_year, :fiscal_quarter, :fiscal_month]
      def hierarchy(name)
        hierarchy_levels[name]
      end
      
      # Get the ordered hierarchy names
      def hierarchies
        @hierarchies ||= []
      end
      
      # Get the hierarchy levels hash
      def hierarchy_levels
        @hierarchy_levels ||= {}
      end
      
      # Return a symbol used when referring to this dimension. The symbol is
      # calculated by demodulizing and underscoring the
      # dimension's class name and then removing the trailing _dimension.
      # 
      # Example: DateDimension will return a symbol :date
      def sym
        self.name.demodulize.underscore.gsub(/_dimension/, '').to_sym
      end
      
      # Get the table name. By default the table name will be the name of the
      # dimension in singular form.
      #
      # Example: DateDimension will have a table called date_dimension
      def table_name
        name = self.name.demodulize.underscore
        set_table_name(name)
        name
      end
      
      # Convert the given name into a dimension class name
      def class_name(name)
        dimension_name = name.to_s
        dimension_name = "#{dimension_name}_dimension" unless dimension_name =~ /_dimension$/
        dimension_name.classify
      end
      
      # Get a class for the specified named dimension
      def class_for_name(name)
        class_name(name).constantize
      end
      
      # Return the time when the underlying dimension source file was last
      # modified. This is used
      # to determine if a cube structure rebuild is required
      def last_modified
        File.new(__FILE__).mtime
      end
      
      # Get the dimension class for the specified dimension parameter. The
      # dimension parameter may be a class, String or Symbol.
      def to_dimension(dimension)
        return dimension if dimension.is_a?(Class) and dimension.ancestors.include?(Dimension)
        return class_for_name(dimension)
      end
      
      # Returns a hash of all of the values at the specified hierarchy level 
      # mapped to the count at that level. For example, given a date dimension
      # with years from 2002 to 2004 and a hierarchy defined with:
      # 
      #  hierarchy :cy, [:calendar_year, :calendar_quarter, :calendar_month_name] 
      #
      # ...then...
      #
      #  DateDimension.denominator_count(:cy, :calendar_year, :calendar_quarter)
      #  returns {'2002' => 4, '2003' => 4, '2004' => 4}
      # 
      # If the denominator_level parameter is omitted or nil then:
      #
      #  DateDimension.denominator_count(:cy, :calendar_year) returns
      #  {'2003' => 365, '2003' => 365, '2004' => 366}
      #
      def denominator_count(hierarchy_name, level, denominator_level=nil)
        if hierarchy_levels[hierarchy_name].nil?
          raise ArgumentError, "The hierarchy '#{hierarchy_name}' does not exist in your dimension #{name}"
        end
        
        q = nil
        # If the denominator_level is specified and it is not the last element
        # in the hierarchy then do a distinct count. If
        # the denominator level is less than the current level then raise an
        # ArgumentError. In other words, if the current level is
        # calendar month then passing in calendar year as the denominator level
        # would raise an ArgumentErro.
        #
        # If the denominator_level is not specified then assume the finest grain
        # possible (in the context of a date dimension this would be each day)
        # and use the id to count.
        if denominator_level && hierarchy_levels[hierarchy_name].last != denominator_level
          level_index = hierarchy_levels[hierarchy_name].index(level)
          denominator_index = hierarchy_levels[hierarchy_name].index(denominator_level)

          if level_index.nil?
            raise ArgumentError, "The level '#{level}' does not appear to exist"
          end
          if denominator_index.nil?
            raise ArgumentError, "The denominator level '#{denominator_level}' does not appear to exist"
          end
          if hierarchy_levels[hierarchy_name].index(denominator_level) < hierarchy_levels[hierarchy_name].index(level)
            raise ArgumentError, "The index of the denominator level '#{denominator_level}' in the hierarchy '#{hierarchy_name}' must be greater than or equal to the level '#{level}'"
          end

          q = "select #{level} as level, count(distinct(#{denominator_level})) as level_count from #{table_name} group by #{level}"
        else
          q = "select #{level} as level, count(id) as level_count from #{table_name} group by #{level}"
        end
        denominators = {}
        connection.select_all(q).each do |row|
          denominators[row['level']] = row['level_count'].to_i
        end
        denominators
      end
      
      # Get the foreign key for this dimension which is used in Fact tables.
      # 
      # Example: DateDimension would have a foreign key of date_id
      #
      # The actual foreign key may be different and depends on the fact class.
      # You may specify the foreign key to use for a specific fact using the
      # Fact#set_dimension_options method.
      def foreign_key
        table_name.sub(/_dimension/,'') + '_id'
      end
      
      # Get an array of the available values for a particular hierarchy level
      # For example, given a DateDimension with data from 2002 to 2004:
      #
      #  available_values('calendar_year') returns ['2002','2003','2004']
      def available_values(level)
        level_method = level.to_sym
        level = connection.quote_column_name(level.to_s)
        order = level_orders[level] || self.order || level
        
        options = {:select => "distinct #{order.to_s == level.to_s ? '' : order.to_s+','} #{level}", :order => order}
        values = []
        find(:all, options).each do |dim|
          value = dim.send(level_method)
          values << dim.send(level_method) unless values.include?(value)
        end
        values.to_a
      end
      
      # Get an array of child values for a particular parent in the hierachy
      # For example, given a DateDimension with data from 2002 to 2004:
      # 
      # available_child_values(:cy, [2002, 'Q1']) returns
      # ['January', 'Feburary', 'March', 'April']
      def available_child_values(hierarchy_name, parent_values)
        if hierarchy_levels[hierarchy_name].nil?
          raise ArgumentError, "The hierarchy '#{hierarchy_name}' does not exist in your dimension #{name}"
        end

        levels = hierarchy_levels[hierarchy_name]
        if levels.length <= parent_values.length
          raise ArgumentError, "The parent_values '#{parent_values.to_yaml}' exceeds the hierarchy depth #{levels.to_yaml}"
        end
        
        child_level = levels[parent_values.length].to_s
        
        # Create the conditions array. Will work with 1.1.6.
        conditions_parts = []
        conditions_values = []
        parent_values.each_with_index do |value, index|
          conditions_parts << "#{levels[index]} = ?"
          conditions_values << value
        end
        conditions = [conditions_parts.join(' AND ')] + conditions_values unless conditions_parts.empty?
        
        child_level_method = child_level.to_sym
        child_level = connection.quote_column_name(child_level)
        order = level_orders[child_level] || self.order || child_level
        
        select_sql = "distinct #{child_level}"
        select_sql += ", #{order}" unless order == child_level
        options = {:select => select_sql, :order => order}

        options[:conditions] = conditions unless conditions.nil?
        values = []
        find(:all, options).each do |dim|
          value = dim.send(child_level_method)
          values << dim.send(child_level_method) unless values.include?(value)
        end
        values.to_a
      end
      alias :available_children_values :available_child_values
      
      # Get a tree of Node objects for all of the values in the specified hierarchy.
      def available_values_tree(hierarchy_name)
        root = value_tree_cache[hierarchy_name]
        if root.nil?
          root = Node.new('All', '__ROOT__')
          levels = hierarchy(hierarchy_name)
          nodes = {nil => root}
          level_list = levels.collect{|level| connection.quote_column_name(level) }.join(',')
          order = self.order || level_list
          find(:all, :select => level_list, :group => level_list, :order => order).each do |dim|
            parent_node = root
            levels.each do |level|
              node_value = dim.send(level)
              child_node = parent_node.optionally_add_child(node_value, level)
              parent_node = child_node
            end
          end
          value_tree_cache[hierarchy_name] = root
        end
        root
      end
      
      protected
      # Get the value tree cache
      def value_tree_cache
        @value_tree_cache ||= {}
      end
      
      class Node#:nodoc:
        attr_reader :value, :children, :parent, :level

        def initialize(value, level, parent = nil)
          @children = []
          @value = value
          @parent = parent
          @level = level
        end

        def has_child?(child_value)
          !self.child(child_value).nil?
        end

        def child(child_value)
          @children.each do |c|
            return c if c.value == child_value
          end
          nil
        end

        def add_child(child_value, level)
          child = Node.new(child_value, level, self)
          @children << child
          child
        end
        
        def optionally_add_child(child_value, level)
          c = child(child_value)
          c = add_child(child_value, level) unless c
          c
        end
      end
      
      public
      # Expire the value tree cache. This should be called if the dimension
      def expire_value_tree_cache
        @value_tree_cache = nil
      end
    end
    
    public
    # Expire the value tree cache
    def expire_value_tree_cache
      self.class.expire_value_tree_cache
    end
    
  end
end

require 'active_warehouse/dimension/date_dimension'
require 'active_warehouse/dimension/dimension_view'