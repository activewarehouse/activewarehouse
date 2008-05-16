class Node
  attr_accessor :dimension_value
  attr_accessor :block
  
  def initialize(dimension_value, block)
    @dimension_value = dimension_value
    @block = block
  end
  
  def sub_block
    @sub_block ||= @block.create(self)
  end
  
  def leaf?
    @sub_block.nil?
  end
  
  def coalesce
    starting_blocks = block.dimension_nodes.collect{|n| n.sub_block}
    suffix_coalescing(starting_blocks, sub_block)
  end
  
  private
  
  def suffix_coalescing(blocks, into_block)
#    return blocks[0] if blocks.size == 1
    
    unprocessed_cells = blocks.collect{|b| b.dimension_nodes}.flatten!
    unprocessed_keys = unprocessed_cells.collect{|cell| cell.dimension_value}.uniq.sort!
    
    while !unprocessed_cells.empty?
      key_min = unprocessed_keys.shift
      to_merge, unprocessed_cells = unprocessed_cells.partition{|cell| cell.dimension_value == key_min}
      
      if into_block.is_leaf_block?
        into_block.add_fact_nodes(key_min, to_merge)
      else
        sub_dwarfs = to_merge.collect{|tm| tm.sub_block}
        new_node = into_block.add_node(key_min)
        suffix_coalescing(sub_dwarfs, new_node.sub_block)
      end
    end
    
    into_block.close unless into_block.closed?
  end
  
end

class FactNode < Node
  attr_reader :count
  
  def initialize(dimension_value, block)
    super(dimension_value, block)
    @count = 0
    @is_all = (dimension_value == :all)
    init_facts
  end
  
  def facts=(facts)
    @count = @count + 1
    add_facts(facts)
  end
  
  def facts
    raise NotImplementedError, "Subclasses must implement this"
  end
  
  protected
  
  def add_facts(facts)
    raise NotImplementedError, "Subclasses must implement this"
  end
  
  def init_facts
    raise NotImplementedError, "Subclasses must implement this"
  end
  
end

class OneFactNode < FactNode
  def facts
    [@fact0]
  end
  
  protected
  
  def add_facts(facts)
    @fact0 += facts[0]
  end
  
  def init_facts
    @fact0 = 0
  end
end

class TwoFactNode < OneFactNode
  def facts
    super << @fact1
  end
  
  protected
  
  def add_facts(facts)
    super(facts)
    @fact1 += facts[1]
  end
  
  def init_facts
    super
    @fact1 = 0
  end
end

class ThreeFactNode < TwoFactNode
  def facts
    super << @fact2
  end
  
  protected
  
  def add_facts(facts)
    super(facts)
    @fact2 += facts[2]
  end
  
  def init_facts
    super
    @fact2 = 0
  end
end

class FactNodeFactory
  def initialize(num_facts)
    @num_facts = num_facts
    @fact_class = case @num_facts
      when 1 : OneFactNode
      when 2 : TwoFactNode
      when 3 : ThreeFactNode
      when 4 : FourFactNode
      when 5 : FiveFactNode
      when 6 : SixFactNode
      else raise ArgumentError, "Can't handle #{@num_facts} facts yet"
    end
  end
  
  def create(dimension_value, block)
    @fact_class.new(dimension_value, block)
  end
end

class Block
  attr_reader :level
  attr_reader :all_node
  attr_reader :nodes
  
  def initialize(num_dimensions, fact_node_factory, parent_node = nil)
    @num_dimensions = num_dimensions
    @parent_node = parent_node
    @level =  @parent_node ? @parent_node.block.level+1 : 0
    @n_level = @level + 1
    @nodes = {}
    @fact_node_factory = fact_node_factory
    @leaf_block = (@n_level == @num_dimensions)
    @closed = false
  end
  
  def to_s
    str = "Block #{self.object_id}, Level: #{level}, Nodes: ["
    str += "#{@nodes.keys.join(',')}], leaf: #{@leaf_block}"
  end
  
  def add_node(dimension_value)
    @nodes[dimension_value] ||= Node.new(dimension_value, self)
  end
  
  def closed?
    @closed
  end
  
  def is_leaf_block?
    @leaf_block
  end
  
  def parent_block
    @parent_node ? @parent_node.block : nil
  end
  
  def create(parent_node)
    Block.new(@num_dimensions, @fact_node_factory, parent_node)
  end
  
  def dimension_nodes
    @nodes.collect{|k,v| v}
  end
  
  def close
    if @leaf_block
      @all_node = @fact_node_factory.create(:all, self)
      dimension_nodes.each {|n| @all_node.facts = n.facts}
    else
      @all_node = Node.new(:all, self)
      @all_node.coalesce
    end
    @closed = true
  end
  
  def add_fact_nodes(dimension_value, nodes)
    new_fact_node = @fact_node_factory.create(dimension_value, self)
    nodes.each {|n| new_fact_node.facts = n.facts }
    @nodes[dimension_value] = new_fact_node
  end
  
  def add_tuple(dimensions, facts)
    dimension_value = dimensions[@level]
    
    if @leaf_block
      @nodes[dimension_value] ||= @fact_node_factory.create(dimension_value, self)
      @nodes[dimension_value].facts = facts
      return self
    else
      @nodes[dimension_value] ||= Node.new(dimension_value, self)
      return @nodes[dimension_value].sub_block.add_tuple(dimensions, facts)
    end
  end
  
end

class DwarfBuilder
  def initialize(filename, field_sep, num_dimensions, num_facts)
    @filename = filename
    @field_sep = field_sep
    @num_dimensions = num_dimensions
    @last_dim_index = @num_dimensions-1
    @num_facts = num_facts
    @root_block = Block.new(@num_dimensions, FactNodeFactory.new(num_facts))
  end
  
  def process
    i = 0
    last_tuple = nil
    leaf_block = nil
    
    puts "#{Time.now} - start"
    
    File.foreach(@filename) do |line|
      row = line.chomp.split(@field_sep)
      dimensions = row[0,@num_dimensions]
      facts = row[@num_dimensions, @num_facts].collect {|r| r.to_i}
      (@num_facts-facts.size).times { facts << 0 } if facts.size < @num_facts
      
      if last_tuple.nil?
        leaf_block = @root_block.add_tuple(dimensions, facts)
        last_tuple = dimensions
        next
      end
      
      prefix = calculate_prefix(dimensions, last_tuple)
      
      if prefix < @num_dimensions
        count = @num_dimensions - prefix - 2
        close_me = leaf_block
        while count >= 0
          close_me.close
          close_me = close_me.parent_block
          count -= 1
        end
      end
      
      leaf_block = @root_block.add_tuple(dimensions, facts)
      last_tuple = dimensions
      
      i += 1
      puts "#{Time.now} - 100000 lines" if i % 100000 == 0
    end
    
    leaf_block.close
    parent = leaf_block.parent_block
    while parent
      parent.close
      parent = parent.parent_block
    end
    
    @root_block
  end
  
  private
  
  def calculate_prefix(current_tuple, last_tuple)
    prefix = 0
    current_tuple.each_with_index do |t,i|
      (t == last_tuple[i]) ? prefix += 1 : break
    end
    prefix
  end
end

class RowColumnBlockQuery
  def initialize(root_block, dimension_names, fact_names)
    @root_block = root_block
    @dimension_names = dimension_names
    @fact_names = fact_names
  end
  
  def query(row, column, options = {})
    conditions = options[:conditions] || {}
    results = []
    
    build_results(@root_block, [row,column], conditions, results)
    
    results = pivot_results(results, [row,column], options[:pivot]) if options[:pivot]
    results = sort_results(results, options[:order_by], options[:order_direction]) if options[:order_by]
    if options[:limit] || options[:offset]
      results = limit_offset_results(results, options[:limit], options[:offset])
    end
    results
  end
    
  private
  
  def pivot_results(results, dimensions, pivot)
    return results if pivot.nil? or pivot.empty?
    pivoted_dimension_name = pivot[:for]
    report_dimension_name = dimensions.find{|n| n != pivoted_dimension_name}
    pivot_values = pivot[:in]
    fact_names = pivot[:facts]
    new_results = []
    
    results.each do |r|
      row_value = r[report_dimension_name]
      col_value = r[pivoted_dimension_name]
      facts = fact_names.inject({}) {|memo,fn| memo[fn] = r[fn]; memo}
      
      new_result = new_results.find{|n| n[report_dimension_name] == row_value}
      
      if new_result.nil?
        new_result = {report_dimension_name => row_value}
        pivot_values.each do |pv|
          fact_names.each do |fn|
            new_result["#{fn}_#{pv}"] = 0
          end
        end
        new_results << new_result
      end
      
      fact_names.each do |fn|
        col_name = "#{fn}_#{col_value}"
        new_result[col_name] += r[fn]
      end
    end
    
    new_results
  end
  
  def build_results(block, dims, conditions, results, working_set = {})
    dimension_name = @dimension_names[block.level]
    found_dim = dims.include?(dimension_name)
    is_leaf = (block.level == @dimension_names.size-1)
    dimension_condition = conditions[dimension_name]
    
    if is_leaf && !found_dim
      result = create_result(block.all_node, working_set)
      results << result if passes_conditions(result, conditions)
    elsif is_leaf && found_dim
      nodes = (dimension_condition ? [block.nodes[dimension_condition]] : block.dimension_nodes)
      nodes.each do |node|
        result = create_result(node, working_set)
        result[dimension_name] = node.dimension_value
        results << result if passes_conditions(result, conditions)
      end
    elsif found_dim
      nodes = (dimension_condition ? [block.nodes[dimension_condition]] : block.dimension_nodes)
      nodes.each do |node|
        working_set[dimension_name] = node.dimension_value
        build_results(node.sub_block, dims, conditions, results, working_set)
        working_set.delete(dimension_name)
      end
    elsif dimension_condition
      build_results(block.nodes[dimension_condition].sub_block, dims, conditions, results, working_set)
    else
      build_results(block.all_node.sub_block, dims, conditions, results, working_set)
    end
  end
  
  def passes_conditions(result, conditions)
    @fact_names.each do |fn|
      return false if conditions[fn] && result[fn] != conditions[fn]
    end
    return true
  end
  
  def create_result(node, working_set)
    result = {:count => node.count}
    result.merge!(working_set)
    @fact_names.each_with_index {|fn,i| result[fn] = node.facts[i]}
    result
  end
  
  def sort_results(results, order_by, order_direction = 'asc')
    order_direction ||= 'asc'
    desc = order_direction =~ /desc/i
    results.sort do |x,y|
      cmp = nil
      order_by.each do |o|
        cmp = x[o] <=> y[o]
        cmp *= -1 if desc
        break unless cmp == 0
      end
      cmp
    end
  end
  
  def limit_offset_results(results, limit, offset=0)
    offset ||= 0
    limit ||= results.length - offset
    results.slice(offset, limit)
  end

end