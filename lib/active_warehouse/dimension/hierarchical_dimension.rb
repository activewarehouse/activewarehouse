module ActiveWarehouse #:nodoc
  # Implements a hierarchical dimension. Including the 
  # <tt>acts_as_hierarchical_dimension</tt> directive in a dimension will add
  # methods for accessing the parent and children of any node in the hierarchy.
  module HierarchicalDimension
    def self.included(base) #:nodoc
      base.extend(ClassMethods)
    end
    
    module ClassMethods #:nodoc
      # Indicates that a dimension is a variable-depth hierarchy.
      def acts_as_hierarchy_dimension
        unless hierarchical_dimension?
           class << self
             # Get the bridge class for this dimension
             def bridge_class
               unless @bridge_class
                 unless Object.const_defined?(bridge_class_name.to_sym)
                   Object.const_set(bridge_class_name.to_sym, Class.new(ActiveWarehouse::Bridge))
                 end
                 @bridge_class = Object.const_get(bridge_class_name.to_sym)
               end
               @bridge_class
             end

             # Get the bridge class name for this hierarchical dimension
             def bridge_class_name
               @child_hierarchy_relationship.class_name || @parent_hierarchy_relationship.class_name
             end

            # Define the child relationship on the bridge table to the dimension
            # table. We can specify a different class name for the bridge table
            # and different foreign-key.
            def child_bridge(association_id, options = {})
              options[:class_name] ||= name.gsub(/Dimension$/, 'HierarchyBridge')
              options[:foreign_key] ||= "parent_id"
              has_many association_id, options
              @child_hierarchy_relationship = reflections[association_id]
            end

            # Define the parent relationship on the bridge table to the dimension
            # table. 
            def parent_bridge(association_id, options = {})
              options[:class_name] ||= name.gsub(/Dimension$/, 'HierarchyBridge')
              options[:foreign_key] ||= "child_id"
              has_many association_id, options
              @parent_hierarchy_relationship = reflections[association_id]
            end

            # the foreign key column name on the bridge table for finding the
            # children.
            def child_foreign_key
              @child_hierarchy_relationship.primary_key_name
            end
            
            # the foreign key column name on the bridge table for finding the
            # parent.
            def parent_foreign_key
              @parent_hierarchy_relationship.primary_key_name
            end
            
            # the column name on the bridge table that defines the number of levels
            # from the parent
            def levels_from_parent
              bridge_class.levels_from_parent
            end
           end
        end
        include InstanceMethods
      end
      alias :acts_as_hierarchical_dimension :acts_as_hierarchy_dimension
      
      # Return true if this is a hierarchical dimension
      def hierarchical_dimension?
        self.included_modules.include?(InstanceMethods)
      end
      
    end
    
    module InstanceMethods #:nodoc
      # Get the parent for this node
      def parent
        self.class.find(:first, 
          :select => "a.*",
          :joins => "a join #{self.class.bridge_class.table_name} b on a.id = b.#{self.class.child_foreign_key}", 
          :conditions => ["b.#{self.class.parent_foreign_key} = ? and b.#{self.class.levels_from_parent} = 1", self.id])
      end
  
      # Get the children for this node
      def children
        self.class.find(:all, 
          :select => "a.*",
          :joins => "a join #{self.class.bridge_class.table_name} b on a.id = b.#{self.class.parent_foreign_key}", 
          :conditions => ["b.#{self.class.child_foreign_key} = ? and b.#{self.class.levels_from_parent} = 1", self.id])
      end
    end
    
  end
end