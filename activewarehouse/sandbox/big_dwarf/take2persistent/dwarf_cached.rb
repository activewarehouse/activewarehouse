require 'pp'
require 'active_record'

class NodeCache
  @@node_cache = {}
  @@queue = []
  
  @@counter = 0
  
  MAX_SIZE = 100000
  
  def self.set(node)
    node.id = (@@counter += 1) unless node.id
    add_to_cache(node)
  end
  
  def self.add_to_cache(node)
    return if @@node_cache[node.id]
    while @@queue.size >= MAX_SIZE
      eject(@@queue.unshift)
    end
    #ActiveRecord::Base.logger.debug("Cache ADD for node #{node.id}")
    @@node_cache[node.id] = node
    @@queue << node.id
  end
  
  def self.flush
    while !@@queue.empty?
      eject(@@queue.pop)
    end
  end
  
  def self.eject(node_id)
    #ActiveRecord::Base.logger.debug("Cache EJECT for node #{node_id}")
    node = @@node_cache[node_id]
    persist(node)
    @@node_cache.delete(node_id)
  end
  
  def self.get(node_id)
    node = @@node_cache[node_id]
    if node
      #ActiveRecord::Base.logger.debug("Cache HIT for node #{node_id}")
      return node
    else
      #ActiveRecord::Base.logger.debug("Cache MISS for node #{node_id}")
      node = load(node_id)
      add_to_cache(node)
      return node
    end
  end
  
  def self.load(node_id)
    contents = ActiveRecord::Base.connection.select_value("SELECT contents FROM nodes WHERE id = #{node_id}")
    Marshal.load(contents)
  end
  
  def self.persist(node)
    contents = ActiveRecord::Base.connection.quote(Marshal.dump(node))
    if !node.saved
      node.saved = true
      ActiveRecord::Base.connection.execute("INSERT INTO nodes (id, contents) VALUES (#{node.id}, #{contents})")
    else
      ActiceRecord::Base.connection.execute("UPDATE nodes SET contents = #{contents} WHERE id = #{node.id}")
    end
  end
end

# A Cell holds a value, and points to (dominates) another Node.
# A Cell may also hold facts, if the cell is in a leaf Node.
class Cell
  attr_accessor :child_node_id
  attr_accessor :facts
  attr_accessor :dimension_value
  
  def initialize(dimension_value, child_node = nil)
    @dimension_value = dimension_value
    @child_node_id = child_node.id if child_node
  end
  
  def add_facts(new_facts)
    @facts = Array.new(new_facts.size, 0) if @facts.nil?
    new_facts.each_with_index {|f,i| @facts[i] += f}
  end
  
  def child_node
    return nil if child_node_id.nil?
    return NodeCache.get(child_node_id)
  end
  
end

# A Node contains Cells, and a special ALL Cells.
class Node

  attr_accessor :id
  attr_accessor :saved

  attr_accessor :level
  attr_accessor :closed
  attr_accessor :all_cell
  attr_accessor :cells
  attr_accessor :leaf
  
  def initialize(params = {})
    @level = params[:level]
    @closed = params[:closed]
    @cells = {}
  end
  
  def leaf? ; leaf end
  def closed? ; closed  end
  
  def add_tuple(dimensions, facts, affected_node_ids)
    affected_node_ids << self.id
    
    dimension_value = dimensions[level]
    
    if leaf?
      cell = cells[dimension_value]
      if cell.nil?
        cell = Cell.new(dimension_value)
        cells[dimension_value] = cell
      end
      cell.add_facts(facts)
    else
      cell = cells[dimension_value]
      if cell.nil?
        child_node = Node.new(:level => level+1)
        child_node.leaf = true if (level == dimensions.size-2)
        NodeCache.set(child_node)
        cell = Cell.new(dimension_value, child_node)
        cells[dimension_value] = cell
      end
      cell.child_node.add_tuple(dimensions, facts, affected_node_ids)
    end
  end
  
  def close
    raise "Node #{id} is already closed" if self.closed?
    if !leaf?
      coalesce = []
      cells.values.each {|cell| coalesce << cell.child_node}
      child_node = suffix_coalesce(coalesce)
      all_cell = Cell.new('__ALL__', child_node)
    else
      all_cell = Cell.new('__ALL__')
      cells.values.each {|cell| all_cell.add_facts(cell.facts)}
      all_cell = all_cell
    end
    
    closed = true
  end
  
  def find(path)
    elements = path.split('/')
    key = elements.shift
    key = '__ALL__' if key == '*'
    return (key == '__ALL__') ? all_cell : cells[key] if elements.empty?
    next_node = (key == '__ALL__') ? all_cell.child_node : cells[key].child_node
    return nil unless next_node
    next_node.find(elements.join('/'))
  end
  
  protected
  
  def add_fact_cells(key, fact_cells)
    raise ArgumentError, "Already added a cell for key #{key}" if cells[key]
    new_cell = Cell.new(key)
    fact_cells.each {|c| new_cell.add_facts(c.facts)}
    cells[key] = new_cell
  end
  
  # used during suffix coalescing
  def add_cell(key, child_node)
    raise ArgumentError, "Already have a cell for key #{key}" if cells[key]
    cells[key] = Cell.new(key, child_node)
  end
  
  # returns a single Node (or FactNode)
  def suffix_coalesce(nodes)
    return nodes[0] if nodes.size == 1
    
    node = Node.new(:level=>nodes[0].level)
    node.leaf = true if nodes[0].leaf?
    NodeCache.set(node)
    
    unprocessed_keys = nodes.collect{|n| n.cells.collect{|k,v| v.dimension_value}}.flatten.uniq
    unprocessed_cells = nodes.collect{|n| n.cells.values}.flatten
    
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
    @affected_node_ids = []
    
    # make the root
    NodeCache.set(Node.new(:level => 0))
  end
  
  def from_file(filename, delimiter)
    File.foreach(filename) do |line|
      row = line.chomp.split(delimiter)
      @num_facts.times {|i| index = @num_dimensions + i; row[index] = row[index].to_i}
      process_row(row)
      exit if @row_number == 1000
    end
    finish
    NodeCache.get(1)
  end
  
  def from_array(rows)
    rows.each {|row| process_row(row)}
    finish
    NodeCache.get(1)
  end
  
  private
  
  def finish
    (@num_dimensions-1).downto(0) do |i|
      NodeCache.get(@affected_node_ids[i]).close
    end
    NodeCache.flush
  end
  
  def process_row(row)
    @row_number += 1
    
    if row.size != @total_cols
      raise "Not enough columns found in line #{@row_number}, should be #{@total_cols}"
    end
    
    dimensions = row[0,@num_dimensions]
    facts = row[@num_dimensions, @num_facts]
    
    if @last_dimensions.nil?
      dwarf = NodeCache.get(1)
      dwarf.add_tuple(dimensions, facts, @affected_node_ids)
      @last_dimensions = dimensions
      return
    end
    
    common_prefix_count = calculate_common_prefix(dimensions, @last_dimensions)
    
    if common_prefix_count < @num_dimensions
      count = @num_dimensions - common_prefix_count - 2
      (@num_dimensions-1).downto((@num_dimensions-1)-count) do |i|
        NodeCache.get(@affected_node_ids[i]).close
      end
    end
    
    start_from_node_id = @affected_node_ids[common_prefix_count] || @affected_node_ids[-1]
    @affected_node_ids = @affected_node_ids[0, (common_prefix_count == @num_dimensions) ? common_prefix_count-1 : common_prefix_count]
    
    NodeCache.get(start_from_node_id).add_tuple(dimensions, facts, @affected_node_ids)
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
