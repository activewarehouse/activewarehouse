require 'pp'
require 'test/unit/assertions'
require 'big_dwarf'
include Test::Unit::Assertions

data = []
data << ['bob',     'honolulu', 'y_2008', 1, 20]
data << ['bob',     'honolulu', 'y_2007', 2, 20]
data << ['alice',   'honolulu', 'y_2007', 3, 40]
data << ['charlie', 'new_york', 'y_2008', 4, 10]
data << ['bob',     'new_york', 'y_2006', 3,  5]
data << ['charlie', 'honolulu', 'y_2007', 2, 20]

root_block = Block.new(3, FactNodeFactory.new(2))

data.each do |row|
  root_block.add_tuple(row[0,3], row[3,2])
end

#pp root_block

dimension_names = ['name', 'city', 'year']
fact_names = ['fact1', 'fact2']

query = RowColumnBlockQuery.new(root_block, dimension_names, fact_names)

assert_equal [{'name'=>'charlie', 'fact1_y_2008'=>4, 'fact1_y_2007'=>2, 'fact1_y_2006'=>0},
             {'name'=>'bob', 'fact1_y_2008'=>1, 'fact1_y_2007'=>2, 'fact1_y_2006'=>3},
             {'name'=>'alice', 'fact1_y_2008'=>0, 'fact1_y_2007'=>3, 'fact1_y_2006'=>0}],
             query.query('name','year',
               :pivot=>{:for=>'year',
                        :in=>['y_2006', 'y_2007', 'y_2008'],
                        :facts=>['fact1']},
               :order_by=>['fact1_y_2008'], :order_direction=>'desc')
               
assert_equal [{'name'=>'alice', 'fact1_y_2008'=>0, 'fact1_y_2007'=>3, 'fact1_y_2006'=>0},
              {'name'=>'bob', 'fact1_y_2008'=>1, 'fact1_y_2007'=>2, 'fact1_y_2006'=>3},
              {'name'=>'charlie', 'fact1_y_2008'=>4, 'fact1_y_2007'=>2, 'fact1_y_2006'=>0}],
             query.query('name','year',
               :pivot=>{:for=>'year',
                        :in=>['y_2006', 'y_2007', 'y_2008'],
                        :facts=>['fact1']},
               :order_by=>['fact1_y_2008'])

assert_equal [{'name'=>'alice', 'city'=>'honolulu', 'fact1'=>3, 'fact2'=>40, :count=>1},
              {'name'=>'bob', 'city'=>'honolulu', 'fact1'=>3, 'fact2'=>40, :count=>2},
              {'name'=>'bob', 'city'=>'new_york', 'fact1'=>3, 'fact2'=>5, :count=>1},
              {'name'=>'charlie', 'city'=>'honolulu', 'fact1'=>2, 'fact2'=>20, :count=>1},
              {'name'=>'charlie', 'city'=>'new_york', 'fact1'=>4, 'fact2'=>10, :count=>1}],
              query.query('name', 'city', :order_by=>['name', 'city'])

assert_equal [{'city'=>'honolulu', 'year'=>'y_2007', 'fact1'=>7, 'fact2'=>80, :count=>3},
              {'city'=>'honolulu', 'year'=>'y_2008', 'fact1'=>1, 'fact2'=>20, :count=>1},
              {'city'=>'new_york', 'year'=>'y_2006', 'fact1'=>3, 'fact2'=>5, :count=>1},
              {'city'=>'new_york', 'year'=>'y_2008', 'fact1'=>4, 'fact2'=>10, :count=>1}],
             query.query('city', 'year', :order_by=>['city', 'year'])
             
assert_equal [{'city'=>'honolulu', 'year'=>'y_2007', 'fact1'=>2, 'fact2'=>20, :count=>1}],
             query.query('city', 'year', :order_by=>['city', 'year'],
                         :conditions=>{'city' => 'honolulu', 'name' => 'charlie'})
                         
assert_equal [{'city'=>'honolulu', 'year'=>'y_2008', 'fact1'=>1, 'fact2'=>20, :count=>1}],
             query.query('city', 'year', :order_by=>['city', 'year'],
                         :conditions=>{'fact1' => 1})

assert_equal [{'city'=>'honolulu', 'year'=>'y_2007', 'fact1'=>7, 'fact2'=>80, :count=>3}], 
  query.query('city', 'year', :order_by=>['city', 'year'], :limit=>1)
  
assert_equal [{'city'=>'honolulu', 'year'=>'y_2008', 'fact1'=>1, 'fact2'=>20, :count=>1}], 
  query.query('city', 'year', :order_by=>['city', 'year'], :offset=>1, :limit=>1)
  
assert_equal [{'city'=>'honolulu', 'year'=>'y_2008', 'fact1'=>1, 'fact2'=>20, :count=>1},
              {'city'=>'new_york', 'year'=>'y_2006', 'fact1'=>3, 'fact2'=>5, :count=>1},
              {'city'=>'new_york', 'year'=>'y_2008', 'fact1'=>4, 'fact2'=>10, :count=>1}],
  query.query('city', 'year', :order_by=>['city', 'year'], :offset=>1)
  
new_root_block = nil
File.open('output', 'w') {|f| Marshal.dump(root_block, f)}
File.open('output') {|f| new_root_block = Marshal.load(f)}
query = RowColumnBlockQuery.new(new_root_block, dimension_names, fact_names)
assert_equal [{'city'=>'honolulu', 'year'=>'y_2007', 'fact1'=>7, 'fact2'=>80, :count=>3},
              {'city'=>'honolulu', 'year'=>'y_2008', 'fact1'=>1, 'fact2'=>20, :count=>1},
              {'city'=>'new_york', 'year'=>'y_2006', 'fact1'=>3, 'fact2'=>5, :count=>1},
              {'city'=>'new_york', 'year'=>'y_2008', 'fact1'=>4, 'fact2'=>10, :count=>1}],
             query.query('city', 'year', :order_by=>['city', 'year'])

puts "Everything worked!"
