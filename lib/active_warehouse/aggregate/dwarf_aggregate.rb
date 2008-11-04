module ActiveWarehouse #:nodoc:
  module Aggregate #:nodoc:
    # Implementation of the Dwarf algorithm described in 
    class DwarfAggregate < Aggregate
      include DwarfCommon
      
      # Initialize the aggregate
      def initialize(cube_class)
        super
      end
      
      # Populate the aggregate
      def populate
        create_dwarf_cube(sorted_facts)
      end
      
      # query
      def query(*args)
        options = parse_query_args(*args)
        
        column_dimension_name = options[:column_dimension_name]
        column_hierarchy_name = options[:column_hierarchy_name]
        row_dimension_name = options[:row_dimension_name]
        row_hierarchy_name = options[:row_hierarchy_name]
        conditions = options[:conditions]
        cstage = options[:cstage]
        rstage = options[:rstage]
        filters = options[:filters]
        
        column_dimension = Dimension.class_for_name(column_dimension_name)
        row_dimension = Dimension.class_for_name(row_dimension_name)
        column_hierarchy = column_dimension.hierarchy(column_hierarchy_name)
        row_hierarchy = row_dimension.hierarchy(row_hierarchy_name)
        dimension_ids = {}
        
        dimension_order.each do |d|
          where_clause = []
          sql = "SELECT id FROM #{d.table_name}"
          filters.each do |key, value|
            dimension, column = key.split('.')
            if d.table_name == dimension
              where_clause << "#{dimension}.#{column} = '#{value}'" # TODO: protect from SQL injection
            end
          end
          sql += %Q(\nWHERE\n  #{where_clause.join(" AND\n  ")}) if where_clause.length > 0
          dimension_ids[d] = cube_class.connection.select_values(sql)
        end
        #puts "dimension ids: #{dimension_ids.inspect}"
        
        values = Array.new(cube_class.fact_class.aggregate_fields.length, 0)
        
        home_nodes = []
        filter_nodes(@root_node, dimension_ids, 0, home_nodes)
        #puts "filtered nodes: #{home_nodes.collect(&:id)}"
        
        values
      end
      
      def filter_nodes(node, dimension_ids, depth, filtered_nodes)
        #puts "filtering node #{print_node(node, depth, false)}"
        dimension = dimension_order[depth]
        #puts "dimension at #{depth} is #{dimension}"
        node.cells.each do |c|
          if dimension_ids[dimension].include?(c.key)
            if depth == dimension_order.length - 1
              filtered_nodes << node
            else
              filter_nodes(c.child, dimension_ids, depth+1, filtered_nodes) unless c.child.nil?
            end
          end
        end
      end
      
      # Aggregate the node by summing all of the values in the cells
      # TODO: support aggregations other than sum
      def calculate_aggregate(cells)
        value = Array.new(cells.first.value.length, 0)
        cells.each do |c|
          c.value.each_with_index do |v, index|
            value[index] += v
          end
        end
        value
      end
      
      # Create the dwarf cube with the sorted_facts
      def create_dwarf_cube(sorted_facts)
        last_tuple = nil
        @last_nodes = nil
        sorted_facts.each do |row|
          tuple = row.is_a?(Hash) ? create_tuple(row) : row
          
          prefix = calculate_prefix(tuple, last_tuple)
          
          close_nodes(prefix).each do |n|
            if n.leaf?
              n.all_cell = Cell.new('*', calculate_aggregate(n.cells))
            else
              n.all_cell = Cell.new('*')
              n.all_cell.child = suffix_coalesce(n.children)
            end
            n.processed = true
          end
          
          nodes = create_nodes(tuple, prefix)
          
          write_nodes(nodes)
          last_tuple = tuple
          if @last_nodes.nil? then @root_node = nodes.first end
          @last_nodes = nodes
        end
        
        # Alg 1, Line 13
        last_leaf_node = @last_nodes.last
        last_leaf_node.all_cell = Cell.new('*', calculate_aggregate(last_leaf_node.cells))
        
        # Alg 1, Line 14
        @last_nodes[0..@last_nodes.length - 2].reverse.each do |n|
          n.all_cell = Cell.new('*')
          n.all_cell.child = suffix_coalesce(n.children)
        end
        
        require File.dirname(__FILE__) + '/dwarf_printer'
        puts DwarfPrinter.print_node(@root_node)
      end
      
      # Coalesce the nodes and return a single node
      def suffix_coalesce(nodes)
        if nodes.length == 1
          return nodes[0]
        else
          sub_dwarf = Node.new
          sub_dwarf.leaf = nodes.first.leaf
          
          keys = sorted_keys(nodes)
          keys.each do |k|
            to_merge = []
            nodes.each do |n|
              n.cells.each do |c|
                to_merge << c if c.key == k
              end
            end
            
            if sub_dwarf.leaf?
              cur_aggr = calculate_aggregate(to_merge)    # Alg 2, Line 8
              sub_dwarf.add_cell(Cell.new(k, cur_aggr))   # Alg 2, Line 9
            else
              # Alg 2, Line 11
              cell = Cell.new(k)
              cell.child = suffix_coalesce(to_merge.collect{|c| c.child})
              sub_dwarf.add_cell(cell)
            end
          end
          
          if sub_dwarf.leaf?
            sub_dwarf.all_cell = Cell.new("*", calculate_aggregate(sub_dwarf.cells))
          else
            cell = Cell.new("*")
            cell.child = suffix_coalesce(sub_dwarf.children)
            sub_dwarf.all_cell = cell
          end
        end
        
        sub_dwarf
      end
      
      # Get a list of sorted keys for the cells in the specified nodes
      def sorted_keys(nodes)
        keys = []
        nodes.each do |n|
          n.cells.each do |c|
            keys << c.key
          end
        end
        keys.uniq.sort { |a, b| a <=> b }
      end
      
      # Accessor for the number of dimensions in the cube.
      attr_accessor :number_of_dimensions
      def number_of_dimensions
        @number_of_dimensions ||= cube_class.dimension_classes.length
      end
      
      # Calculates a common prefix between the two tuples
      def calculate_prefix(current_tuple, last_tuple)
        return [] if last_tuple.nil?
        prefix = []
        last_matched_index = nil
        0.upto(number_of_dimensions) do |i|
          if current_tuple[i] == last_tuple[i]
            prefix << current_tuple[i]
          else
            break
          end
        end
        prefix
      end
      
      # Close all of the last nodes that match the specified prefix and return
      # the list of newly closed nodes
      def close_nodes(prefix)
        new_closed = []
        if @last_nodes
          @last_nodes[prefix.length + 1, @last_nodes.length].each do |n|
            n.closed = true
            new_closed << n
          end
        end
        new_closed
      end
      
      # Create the nodes for the current tuple
      def create_nodes(current_tuple, prefix)
        nodes = []
        new_nodes_needed_for = []
        if @last_nodes.nil?
          0.upto(number_of_dimensions - 1) do |i|
            k = current_tuple[i]
            parent_cell = (nodes.last.nil?) ? nil : nodes.last.cells.last
            nodes << Node.new(k, parent_cell)
          end
        else
          if prefix.length > 0
            0.upto(prefix.length - 1) do |i|
              nodes << @last_nodes[i]
            end
          end
          k = current_tuple[prefix.length]
          n = @last_nodes[prefix.length]
          n.add_cell(Cell.new(k))
          nodes << n
          
          (prefix.length + 1).upto(number_of_dimensions - 1) do |i|
            k = current_tuple[i]
            parent_cell = (nodes.last.nil?) ? nil : nodes.last.cells.last
            nodes << Node.new(k, parent_cell)
          end
        end
        
        nodes.last.leaf = true
        cell = nodes.last.cells.last
        unless cell.value
          cell.value = current_tuple[number_of_dimensions..current_tuple.length-1]
        end
        
        nodes
      end
      
      # Write nodes to the filesystem.
      def write_nodes(nodes)
        # open(File.new(cube_class.name + '.dat'), 'w') do |f|
#           
#         end
      end
      
      class Cell
        # The cell key, which will always be a dimension id
        attr_accessor :key
        # The child of the cell which will always be a node
        attr_accessor :child
        # The value of the cell which will only be non-nil in the cells that appear in nodes in the last dimension
        attr_accessor :value
        # The node that this cell is a member of
        attr_accessor :node
        
        def initialize(key, value=nil)
          @key = key
          @value = value
        end
        
        def child=(node)
          node.parent = self
          @child = node
        end
        
        def to_s
          key
        end
      end
      
      class Node
        # A special cell which will hold either a reference to a sub node or the aggregate values for all
        # of the values in the node's cells
        attr_accessor :all_cell
        
        # The parent cell or nil
        attr_accessor :parent
        
        # Set the true if the node is closed
        attr_accessor :closed
        
        # Set to true if the node has been processed
        attr_accessor :processed
        
        # Set to true if this node is a leaf node
        attr_accessor :leaf
        
        # Reader accessor for the node index, a sequential number identifying order of creation
        attr_reader :index

        @@sequence = 0
        
        # Initialize the node with a cell that has the given key
        def initialize(key=nil, parent_cell=nil)
          @closed = false
          @processed = false
          @parent = parent_cell
          @parent.child = self if @parent
          @index = @@sequence += 1
          #puts "creating node #{@index} with parent: #{@parent}"
          add_cell(Cell.new(key)) if key
        end
        
        # Return an array of cells for the node
        def cells
          @cells ||= []
        end
        
        def keys
          cells.collect { |cell| cell.key }
        end
        
        def has_cell_with_key?(key)
          cells.each do |cell|
            return true if cell.key == key
          end
          return false
        end
        
        def child(key)
          cells.each do |cell|
            return cell.child if cell.key == key
          end
          return nil
        end
        
        def children
          cells.collect { |cell| cell.child }.compact
        end
        
        def closed?
          closed
        end
        
        def processed?
          processed
        end
        
        def leaf?
          leaf
        end
        
        def add_cell(cell)
          cell.node = self
          cells << cell
        end
        
        def all_cell=(cell)
          @all_cell = cell
          @all_cell.node = self
        end
        
        def to_s
          index.to_s
        end
      end
    end
  end
end