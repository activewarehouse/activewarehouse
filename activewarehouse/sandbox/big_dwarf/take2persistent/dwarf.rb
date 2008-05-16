require 'pp'
require 'active_record'

# A Cell holds a value, and points to (dominates) another Node.
# A Cell may also hold facts, if the cell is in a leaf Node.
class Cell < ActiveRecord::Base
  belongs_to :node
  belongs_to :child_node, :class_name => 'Node', :foreign_key => 'child_node_id',
                          :include => :cells
  serialize :facts
  
  def child_cells
    return [] if child_node.nil?
    child_node.cells
  end
  
  def add_facts(new_facts)
    self.facts = Array.new(new_facts.size, 0) if self.facts.nil?
    new_facts.each_with_index {|f,i| self.facts[i] += f}
  end
  
end

# A Node contains Cells, and a special ALL Cells.
class Node < ActiveRecord::Base

  has_many :cells
  has_one :parent_cell, :class_name => 'Cell', :foreign_key => 'child_node_id'
  
  def leaf? ; self.leaf == 1 end
  def closed? ; self.closed == 1 end
  def root? ; parent_cell.nil? end
  
  def cell_by_value(value)
    self.cells.detect{|cell| cell.dimension_value == value}
  end
  
  def cells_minus_all
    cells.select{|c| c.dimension_value != "__ALL__"}
  end
  
  def add_tuple(dimensions, facts, affected_nodes)
    affected_nodes << self
    
    dimension_value = dimensions[level]
    
    if leaf?
      cell = cell_by_value(dimension_value)
      cell = cells.build(:dimension_value => dimension_value) unless cell
      cell.add_facts(facts)
      #cell.save!
    else
      cell = cell_by_value(dimension_value)
      if cell.nil?
        child_node = Node.new(:level => level+1)
        child_node.leaf = 1 if (level == dimensions.size-2)
        child_node.save!
        cell = cells.create(:dimension_value => dimension_value, :child_node => child_node)
      end
      cell.child_node.add_tuple(dimensions, facts, affected_nodes)
    end
  end
  
  def close
    raise "Node #{id} is already closed" if self.closed?
    puts "Closing node #{id}"
    if !leaf?
      all_cell = cells.build(:dimension_value => '__ALL__', :all_cell => 1)
      all_cell.child_node = suffix_coalesce(cells_minus_all.collect{|c| c.child_node})
      all_cell.save!
    else
      cells.each {|c| c.save! unless c.id}
      all_cell = cells.build(:dimension_value => '__ALL__', :all_cell => 1)
      cells_minus_all.each {|cell| all_cell.add_facts(cell.facts)}
      all_cell.save!
    end
    
    self.closed = true
    self.save!
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
  
  def add_fact_cells(key, fact_cells)
    raise ArgumentError, "Already added a cell for key #{key}" if cell_by_value(key)
    new_cell = cells.build(:dimension_value => key, :node => self)
    fact_cells.each {|c| new_cell.add_facts(c.facts)}
    new_cell.save!
  end
  
  # used during suffix coalescing
  def add_cell(key, child_node)
    raise ArgumentError, "Already have a cell for key #{key}" if cell_by_value(key)
    cells.create(:dimension_value => key, :child_node => child_node)
  end
  
  # returns a single Node (or FactNode)
  def suffix_coalesce(nodes)
    return nodes[0] if nodes.size == 1
    
    node = Node.new(:level=>nodes[0].level)
    node.leaf = true if nodes[0].leaf?
    node.save!
    
    unprocessed_keys = nodes.collect{|n| n.cells_minus_all.collect{|c| c.dimension_value}}.flatten.uniq
    unprocessed_cells = nodes.collect{|n| n.cells_minus_all}.flatten
    
    while !unprocessed_cells.empty?
      key = unprocessed_keys.shift
      to_merge, unprocessed_cells = unprocessed_cells.partition{|c| c.dimension_value == key}
      
      if node.leaf?
        node.add_fact_cells(key, to_merge)
      else
        node.add_cell(key, suffix_coalesce(to_merge.collect{|tm| tm.child_node}))
      end
    end
    
    node.close
    node.save!
    node
  end
  
end

class DwarfBuilder
  def initialize(num_dimensions, num_facts)
    @num_dimensions, @num_facts = num_dimensions, num_facts
    @total_cols = @num_dimensions + @num_facts
    @row_number = 0

    @last_dimensions = nil
    @last_leaf_node = nil
    @affected_nodes = []
    
    # make the root
    Node.create(:level => 0)
  end
  
  def from_file(filename, delimiter)
    File.foreach(filename) do |line|
      row = line.chomp.split(delimiter)
      @num_facts.times {|i| index = @num_dimensions + i; row[index] = row[index].to_i}
      process_row(row)
    end
    finish
    Node.find(1)
  end
  
  def from_array(rows)
    rows.each {|row| process_row(row)}
    finish
    Node.find(1)
  end
  
  private
  
  def finish
    (@num_dimensions-1).downto(0) do |i|
      @affected_nodes[i].close
    end
  end
  
  def process_row(row)
    @row_number += 1
    
    if row.size != @total_cols
      raise "Not enough columns found in line #{@row_number}, should be #{@total_cols}"
    end
    
    dimensions = row[0,@num_dimensions]
    facts = row[@num_dimensions, @num_facts]
    
    if @last_dimensions.nil?
      dwarf = Node.find(1, :include=>:cells)
      dwarf.add_tuple(dimensions, facts, @affected_nodes)
      @last_dimensions = dimensions
      return
    end
    
    common_prefix_count = calculate_common_prefix(dimensions, @last_dimensions)
    
    if common_prefix_count < @num_dimensions
      count = @num_dimensions - common_prefix_count - 2
      (@num_dimensions-1).downto((@num_dimensions-1)-count) do |i|
        @affected_nodes[i].close
      end
    end
    
    start_from_node = @affected_nodes[common_prefix_count] || @affected_nodes[-1]
    @affected_nodes = @affected_nodes[0, (common_prefix_count == @num_dimensions) ? common_prefix_count-1 : common_prefix_count]
    #dimensions_to_process = dimensions[common_prefix_count,@num_dimensions-common_prefix_count]
    
    start_from_node.add_tuple(dimensions, facts, @affected_nodes)
    @last_dimensions = dimensions
    
    puts "#{Time.now} - Processed 10000 Rows" if @row_number % 10000 == 0
  end
  
  def calculate_common_prefix(current_dimensions, last_dimensions)
    prefix = 0
    current_dimensions.each_with_index do |t,i|
      (t == last_dimensions[i]) ? prefix += 1 : break
    end
    prefix
  end
end
