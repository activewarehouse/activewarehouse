module ActiveWarehouse #:nodoc:
  module Aggregate #:nodoc:
    # Dwarf support class that prints a representation of the Dwarf
    class DwarfPrinter
      # Print the specified node at the given depth.
      def self.print_node(node, depth=0, recurse=true)
        #puts "printing node #{node.index}"
        cells = node.cells.collect { |c| cell_to_string(c)}.join('|')

        parent_node = node.parent ? "#{cell_to_string(node.parent)}:" : ''
        puts "#{node.index}=#{' '*depth}#{parent_node}[#{cells}|#{all_cell_to_string(node.all_cell)}]"
        if !node.leaf?
          print_node(node.all_cell.child, depth + 1, false) if node.all_cell
        end
        if recurse
          node.children.each { |child| print_node(child, depth+1) }
        end
      end
      
      def self.cell_to_string(cell)
        # a new String object must be created here, otherwise to_s returns a reference
        # to the same String object each time and thus the value will be appended each time
        # which is not what I want
        s = String.new(cell.key.to_s)
        s << " #{cell.value.join(',')}" if cell.node.leaf?
        s
      end
      
      def self.all_cell_to_string(cell)
        cell ? (cell.value ? cell.value.inspect : '') : ''
      end
    end
  end
end