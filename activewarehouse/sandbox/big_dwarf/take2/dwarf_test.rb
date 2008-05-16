require 'test/unit'
require 'dwarf'

class DwarfTest < Test::Unit::TestCase

  def test_one_row_four_dims
    rows = [['alice', 'honolulu', '2007', 'jan', 1, 2]]
    
    root_node = DwarfBuilder.new(4, 2).from_array(rows)
    assert_not_nil root_node
    assert root_node.root?
    assert_equal 0, root_node.level
    
    assert_equal 1, root_node.cells.size
    alice_cell = root_node.cells['alice']
    assert_not_nil alice_cell
    assert !alice_cell.leaf?
    
    assert_equal 1, alice_cell.child_cells.size
    honolulu_cell = alice_cell.child_cells['honolulu']
    assert_not_nil honolulu_cell
    assert_equal 1, honolulu_cell.node.level
    
    assert_equal 1, honolulu_cell.child_cells.size
    _2007_cell = honolulu_cell.child_cells['2007']
    assert_not_nil _2007_cell
    assert _2007_cell.node.closed?
    assert_equal 2, _2007_cell.node.level
    
    assert_equal 1, _2007_cell.child_cells.size
    alice_2007_jan_cell = _2007_cell.child_cells['jan']
    assert_not_nil alice_2007_jan_cell
    assert_equal 3, alice_2007_jan_cell.node.level
    assert alice_2007_jan_cell.leaf?
    assert_equal [1,2], alice_2007_jan_cell.facts
    
    all_cell = alice_2007_jan_cell.node.all_cell
    assert_not_nil all_cell
    assert alice_2007_jan_cell.node.closed?
    assert_equal [1,2], all_cell.facts
    assert_equal 3, all_cell.node.level
    
    # ensure suffix coalescing works
    assert_equal alice_cell.node.all_cell.child_node, honolulu_cell.node
    assert_equal honolulu_cell.node.all_cell.child_node, _2007_cell.node
    assert_equal _2007_cell.node.all_cell.child_node, alice_2007_jan_cell.node
  end
  
  def test_two_rows_four_dims
    rows = [['alice', 'honolulu', '2007', 'jan', 1, 2],
            ['bob',   'honolulu', '2008', 'jan', 3, 4]]
    
    root_node = DwarfBuilder.new(4, 2).from_array(rows)
    assert_not_nil root_node
    assert root_node.root?
    assert_equal 0, root_node.level
    
    assert_equal 2, root_node.cells.size
    alice_cell = root_node.cells['alice']
    assert_not_nil alice_cell
    assert !alice_cell.leaf?
    
    bob_cell = root_node.cells['bob']
    assert_not_nil bob_cell
    assert !bob_cell.leaf?
    assert_equal 0, bob_cell.node.level
    
    assert_equal 1, alice_cell.child_cells.size
    honolulu_cell = alice_cell.child_cells['honolulu']
    assert_not_nil honolulu_cell
    assert_equal 1, honolulu_cell.node.level
    
    assert_equal 1, honolulu_cell.child_cells.size
    _2007_cell = honolulu_cell.child_cells['2007']
    assert_not_nil _2007_cell
    assert _2007_cell.node.closed?
    
    assert_equal 1, _2007_cell.child_cells.size
    alice_2007_jan_cell = _2007_cell.child_cells['jan']
    assert_not_nil alice_2007_jan_cell
    assert alice_2007_jan_cell.leaf?
    assert_equal [1,2], alice_2007_jan_cell.facts
    
    all_cell = alice_2007_jan_cell.node.all_cell
    assert_not_nil all_cell
    assert alice_2007_jan_cell.node.closed?
    assert_equal [1,2], all_cell.facts
    
    # check bob now
    bob_hon_node = bob_cell.child_node
    assert_not_nil bob_hon_node
    assert_equal 1, bob_hon_node.cells.size
    assert_not_nil bob_hon_node.all_cell
    assert_not_nil bob_hon_node.cells['honolulu']
    
    bob_hon_2008_node = bob_hon_node.cells['honolulu'].child_node
    assert_not_nil bob_hon_2008_node
    assert_equal 1, bob_hon_2008_node.cells.size
    assert_not_nil bob_hon_2008_node.all_cell
    assert_not_nil bob_hon_2008_node.cells['2008']
    assert_equal 2, bob_hon_2008_node.level
    
    bob_2008_cell = bob_hon_2008_node.cells['2008']
    assert_not_nil bob_2008_cell
    bob_2008_jan_cell = bob_2008_cell.child_node.cells['jan']
    assert_not_nil bob_2008_jan_cell
    assert bob_2008_jan_cell.node.closed?
    assert_equal [3,4], bob_2008_jan_cell.facts
    
    # ensure suffix coalescing works
    assert_equal honolulu_cell.node.all_cell.child_node, _2007_cell.node
    assert_equal _2007_cell.node.all_cell.child_node, alice_2007_jan_cell.node
    
    # ensure s.c. works with different rows
    root_all_cell = root_node.all_cell
    assert_not_nil root_all_cell
    assert_not_nil root_all_cell.child_node
    all_honolulu_cell = root_all_cell.child_node.cells['honolulu']
    assert_not_nil all_honolulu_cell
    all_years_node = all_honolulu_cell.child_node
    assert_not_nil all_years_node
    assert_equal 2, all_years_node.cells.size
    assert all_years_node.cells.keys.include?('2007')
    assert all_years_node.cells.keys.include?('2008')
    
    # more s.c. testing!
    assert_equal all_years_node.cells['2007'].child_node, alice_2007_jan_cell.node
    assert_equal all_years_node.cells['2008'].child_node, bob_2008_jan_cell.node
    
    # did everything add up?
    assert_equal [4, 6], all_years_node.all_cell.child_node.cells['jan'].facts
    assert_equal [4, 6], all_years_node.all_cell.child_node.all_cell.facts
  end
  
  def test_three_rows_with_a_prefix_match
    rows = [['alice', 'honolulu', '2007', 'jan', 1, 2],
            ['bob',   'honolulu', '2008', 'jan', 3, 4],
            ['bob',   'honolulu', '2007', 'feb', 5, 6]]
    
    root_node = DwarfBuilder.new(4, 2).from_array(rows)
    assert_not_nil root_node
    assert root_node.root?
    
    # test all sum (group by nothing)
    all_cell = root_node.find("*/*/*/*")
    assert_not_nil all_cell
    assert_equal [9, 12], all_cell.facts
  end
end