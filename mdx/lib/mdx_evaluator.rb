require 'mdx_grammar'

class MDXEvaluator < Dhaka::Evaluator

  self.grammar = MDXGrammar

  define_evaluation_rules do
    
    for_expression do
      evaluate(child_nodes[0])
    end
    
    for_with_select_from do
      puts "with select from"
    end
    
    for_select_from do
      puts "select from"
      evaluate(child_nodes[1]) # what to select
      evaluate(child_nodes[3]) # where to select from
    end
    
    for_select_query_axis_clause do

    end
    for_select_all do
      puts "select all"
    end
    
    for_select_subcube_clause do
      puts "select subcube clause"
      puts child_nodes.inspect
    end
    for_select_subcube_clause_with_where do
      puts "select subcube clause with where"
    end
    
    for_slicer do
      puts "slicer"
    end
    for_cell_property_list do
      puts "cell property list"
    end
    for_slicer_and_cell_property_list do
      puts "slicer and cell property list"
    end
    
    for_cell_calculation do
      puts "cell calculation"
    end
    for_calculated_member do
      puts "calculated member"
    end
    for_member do
      puts "member"
    end
    for_set_clause do
      puts "set clause"
    end
    
    for_clause_single do
      puts "clause single"
    end
    for_clause do
      puts "clause"
    end
    for_recursive_clause do
      puts "recursive clause"
    end
    for_on_columns do
      puts "on columns"
    end
    for_on_rows do
      puts "on rows"
    end
    for_cube_name do
      
    end
    for_subcube_clause do
      
    end
    for_where do
      
    end
    for_single_slice do
      
    end
    for_single_slice_with_parens do
      
    end
    for_multiple_slice do
      
    end
    for_multiple_slice_with_parens do
      
    end
    for_multiple_part_with_brackets do
      
    end
    for_multiple_tuple_expression do
      
    end
    for_mdx_expression_function do
    end
    for_multiple_part do
    end
    for_single_slicer_expression_with_parens do
    end
    for_set_expression_with_braces do
      
    end
    for_multiple_name_part do
      
    end
    for_single_part_with_brackets do
      
    end
    for_member_body_clause_as do
      
    end
    
    # Initialize the evaluator with the given output stream for writing error
    # messages.
    def initialize(output_stream)
      @output_stream = output_stream
    end
    
  end
end