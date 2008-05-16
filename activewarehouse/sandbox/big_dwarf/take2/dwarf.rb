require 'pp'

# A Cell holds a value, and points to (dominates) another Node.
class Cell
  attr_reader :node
  attr_reader :value
  attr_reader :child_node
  
  def initialize(node, value, child_node = nil)
    @node, @value, @child_node = node, value, child_node
  end
  
  def leaf? ; @child_node.nil? end
  
  def child_cells
    return [] if @child_node.nil?
    @child_node.cells
  end
end

# A Fact Cell holds facts as well as a dimension value
class FactCell < Cell
  attr_reader :facts
  
  def initialize(node, value)
    super(node, value)
    @facts = nil
  end
  
  def add_facts(facts)
    @facts = Array.new(facts.size, 0) if @facts.nil?
    facts.each_with_index {|f,i| @facts[i] += f}
  end
end

# A Node contains Cells, and a special ALL Cells.
class Node
  attr_reader :cells
  attr_reader :all_cell
  attr_writer :parent_cell
  attr_reader :level
  
  def initialize(level = 0)
    @level = level
    @leaf = false
    @cells = {}
    @all_cell = nil
    @closed = false
  end
  
  def leaf? ; @leaf end
  def closed? ; @closed end
  def root? ; @parent_node.nil? end
  def parent_node ; @parent_cell ? @parent_cell.node : nil end
  
  def add_tuple(dimensions, facts)
    dimension_value = dimensions[@level]
    
    if @level == dimensions.size-1
      @leaf = true
      @cells[dimension_value] ||= FactCell.new(self, dimension_value)
      @cells[dimension_value].add_facts(facts)
      return self
    else
      if @cells[dimension_value].nil?
        child_node = (@level == dimensions.size-2) ? FactNode.new(@level+1) : Node.new(@level+1)
        @cells[dimension_value] = Cell.new(self, dimension_value, child_node)
        child_node.parent_cell = @cells[dimension_value]
      end
      return @cells[dimension_value].child_node.add_tuple(dimensions, facts)
    end
  end
  
  def close
    do_close
    @closed = true
  end
  
  def find(path)
    elements = path.split('/')
    key = elements.shift
    key = :all if key == '*'
    return (key == :all) ? @all_cell : @cells[key] if elements.empty?
    next_node = (key == :all) ? @all_cell.child_node : @cells[key].child_node
    return nil unless next_node
    next_node.find(elements.join('/'))
  end
  
  protected
  
  # used during suffix coalescing
  def add_cell(key, child_node)
    raise ArgumentError, "Already have a cell for key #{key}" if @cells[key]
    @cells[key] = Cell.new(self, key, child_node)
  end
  
  def do_close
    @all_cell = Cell.new(self, :all, suffix_coalesce(@cells.collect{|k,v| v.child_node}))
  end
  
  # returns a single Node (or FactNode)
  def suffix_coalesce(nodes)
    return nodes[0] if nodes.size == 1
    
    node = nodes[0].leaf? ? FactNode.new(nodes[0].level) : Node.new(nodes[0].level)
    unprocessed_keys = nodes.collect{|n| n.cells.keys}.flatten.uniq
    unprocessed_cells = nodes.collect{|n| n.cells.values}.flatten
    
    while !unprocessed_cells.empty?
      key = unprocessed_keys.shift
      to_merge, unprocessed_cells = unprocessed_cells.partition{|c| c.value == key}
      
      if node.is_a? FactNode
        node.add_fact_cells(key, to_merge)
      else
        node.add_cell(key, suffix_coalesce(to_merge.collect{|tm| tm.child_node}))
      end
    end
    
    node.close
    node   # is this right??
  end
  
end

class FactNode < Node
  def initialize(level)
    super(level)
    @leaf = true
  end
  
  def add_fact_cells(key, fact_cells)
    raise ArgumentError, "Already added a cell for key #{key}" if @cells[key]
    new_cell = FactCell.new(self, key)
    fact_cells.each {|c| new_cell.add_facts(c.facts)}
    @cells[key] = new_cell
  end
  
  protected
  
  def do_close
    @all_cell = FactCell.new(self, :all)
    cells.each {|k,cell| @all_cell.add_facts(cell.facts)}
  end
end

class DwarfBuilder
  def initialize(num_dimensions, num_facts)
    @num_dimensions, @num_facts = num_dimensions, num_facts
    @total_cols = @num_dimensions + @num_facts
    @dwarf = Node.new
    @row_number = 0
    
    @last_dimensions = nil
    @last_leaf_node = nil
  end
  
  def from_file(filename, delimiter)
    File.foreach(filename) do |line|
      row = line.chomp.split(delimiter)
      @num_facts.times {|i| index = @num_dimensions + i; row[index] = row[index].to_i}
      process_row(row)
    end
    
    finish
    
    @dwarf
  end
  
  def from_array(rows)
    rows.each {|row| process_row(row)}
    finish
    @dwarf
  end
  
  private
  
  def finish
    @last_leaf_node.close
    parent = @last_leaf_node.parent_node
    while parent
      parent.close
      parent = parent.parent_node
    end
  end
  
  def process_row(row)
    if row.size != @total_cols
      raise "Not enough columns found in line #{@row_number}, should be #{@total_cols}"
    end
    
    dimensions = row[0,@num_dimensions]
    facts = row[@num_dimensions, @num_facts]
    
    if @last_dimensions.nil?
      @last_leaf_node = @dwarf.add_tuple(dimensions, facts)
      @last_dimensions = dimensions
      return
    end
    
    common_prefix_count = calculate_common_prefix(dimensions, @last_dimensions)
    
    if common_prefix_count < @num_dimensions
      count = @num_dimensions - common_prefix_count - 2
      close_me = @last_leaf_node
      while count >= 0
        close_me.close
        close_me = close_me.parent_node
        count -= 1
      end
    end
    
    @last_leaf_node = @dwarf.add_tuple(dimensions, facts)
    @last_dimensions = dimensions
    
    @row_number += 1
  end
  
  def calculate_common_prefix(current_dimensions, last_dimensions)
    prefix = 0
    current_dimensions.each_with_index do |t,i|
      (t == last_dimensions[i]) ? prefix += 1 : break
    end
    prefix
  end
end