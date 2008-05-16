require 'rubygems'
require 'dhaka'

class MDXGrammar < Dhaka::Grammar
  
  for_symbol(Dhaka::START_SYMBOL_NAME) do
    expression %w| statement |
  end
  
  for_symbol('statement') do
    with_select_from %w|WITH SelectWithClause SELECT Select FROM From|
    select_from %w|SELECT Select FROM From|
  end
  
  for_symbol('Select') do
    select_query_axis_clause %w|SelectQueryAxisClause|
    select_all %w|*|
  end
  
  for_symbol('From') do
    select_subcube_clause %w|SelectSubcubeClause|
    select_subcube_clause_with_where %w|SelectSubcubeClause FromOptions|
    #select_slicer_axis_clause %w|SelectSlicerAxisClause|
  end
  
  for_symbol('FromOptions') do
    slicer %w|SelectSlicerAxisClause|
    cell_property_list %w|SelectCellPropertyListClause|
    slicer_and_cell_property_list %w|SelectSlicerAxisClause SelectCellPropertyListClause|
  end
  
  for_symbol('SelectWithClause') do
    cell_calculation %w|CELL CALCULATION CreateCellCalculationBodyClause|
    calculated_member %w|CALCULATED MEMBER CreateMemberBodyClause|
    member %w|MEMBER CreateMemberBodyClause|
    set_clause %w|SET CreateSetBodyClause|
  end
  
  for_symbol('SelectQueryAxisClause') do
    clause_single %w|Clause|
  end
  
  for_symbol('Clause') do
    clause %w|SetExpression OnClause|
    recursive_clause %w|SetExpression OnClause , Clause|
  end
  
  for_symbol('OnClause') do
    on_columns %w|ON COLUMNS|
    on_rows %w|ON ROWS|
  end
  
  for_symbol('SelectSubcubeClause') do
    cube_name %w|TupleExpression|
    subcube_clause %w|Select|
  end
  
  for_symbol('SelectSlicerAxisClause') do
    where %w|WHERE SlicerSpecification|
  end
  
  for_symbol('SlicerSpecification') do
    single_slice %w|TupleExpression|
    single_slice_with_parens %w| ( TupleExpression ) |
    multiple_slice %w| TupleExpression , SlicerSpecification |
    multiple_slice_with_parens %w| ( TupleExpression , SlicerSpecification )|
  end
  
  for_symbol('SelectCellPropertyListClause') do
    
  end
  
  for_symbol('CreateCellCalculationBodyClause') do
    
  end
  
  for_symbol('CreateMemberBodyClause') do
    member_body_clause %w|TupleExpression|
    member_body_clause_as %w|TupleExpression AS MDXExpression|
  end
  
  for_symbol('MDXExpression') do
    mdx_expression_function %w|name ( MDXExpression )|
    mdx_expression_properties %w| SetExpression |
  end
  
  for_symbol('CreateSetBodyClause') do
    
  end
  
  for_symbol('SelectCellPropertyListClause') do
    
  end
  
  for_symbol('SelectDimensionPropertyListClause') do
    
  end
  
  for_symbol('SetExpression') do
    single_tuple_expression %w|TupleExpression|
    multiple_tuple_expression %w|TupleExpression , SetExpression|
    set_expression_with_braces %w|{ SetExpression }|
  end
  
  for_symbol('TupleExpression') do
    single_part %w|Name|
    single_part_with_brackets %w| [ Name ] |
    multiple_part %w|Name . TupleExpression|
    multiple_part_with_brackets %w| [ Name ] . TupleExpression|
  end
  
  for_symbol('SlicerExpression') do
    single_slicer_expression %w| TupleExpression |
    single_slicer_expression_with_parens %w| ( TupleExpression ) |
  end
  
  for_symbol('Name') do
    name_part %w|name|
    multiple_name_part %w|name Name|
  end
  
end

parser = Dhaka::Parser.new(MDXGrammar)
File.open(File.dirname(__FILE__) + '/mdx_parser.rb', 'w') { |f| f << parser.compile_to_ruby_source_as(:MDXParser)}