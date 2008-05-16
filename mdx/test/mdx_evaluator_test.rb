require File.dirname(__FILE__) + '/test_helper'

class MDXEvaluatorTest < Test::Unit::TestCase
  def tokenize_error_message(unexpected_char_index, program)
    "Unexpected character #{program[unexpected_char_index].chr}:\n#{program.dup.insert(unexpected_char_index, ERROR_MARKER)}"
  end
  
  def evaluation_error_message(evaluation_result, program)
    "#{evaluation_result.exception}:\n#{program.dup.insert(evaluation_result.node.tokens[0].input_position, ERROR_MARKER)}"
  end
  
  def test_select_all
    q = "SELECT * FROM orders"
    assert_nothing_raised do
      parse_result = MDXParser.parse(MDXLexer.lex(q))
      assert_equal Dhaka::ParseSuccessResult, parse_result.class
      evaluation_result = MDXEvaluator.new(output_stream = []).evaluate(parse_result)
    end
  end
  
  def test_select_specific
    q = "SELECT 
      date.calendar.calendar_year ON COLUMNS,
      product.category.children ON ROWS
      FROM orders"
    assert_nothing_raised do
      parse_result = MDXParser.parse(MDXLexer.lex(q))
      assert_equal Dhaka::ParseSuccessResult, parse_result.class, parse_result.inspect
      evaluation_result = MDXEvaluator.new(output_stream = []).evaluate(parse_result)
    end
  end
end

