require File.dirname(__FILE__) + '/test_helper'

class MDXLexerTest < Test::Unit::TestCase
  def test_tokenizes
    input = "
    WITH MEMBER date.calendar.first8months2003 AS
      Aggregate
    SELECT 
      date.calendar.calendar_year ON COLUMNS,
      product.category.children ON ROWS
    FROM
      orders
    WHERE
      order_facts.order_quantity
    "
    assert_equal(%w(
      WITH MEMBER name . name . name AS name SELECT 
      name . name . name ON COLUMNS , 
      name . name . name ON ROWS
      FROM name 
      WHERE name . name
    ), lex(input)
    )
  end
  
  def test_tokenize_q2
    input = "SELECT {[Measures].[Unit Sales], [Measures].[Store Sales]} ON COLUMNS,
    {[Product].members} ON ROWS
    FROM [Sales]
    WHERE [Time].[1997].[Q2]"
    
    assert_equal(%w(
      SELECT { [ name ] . [ name name ] , [ name ] . [ name name ] } ON COLUMNS 
      , { [ name ] . name } ON ROWS FROM [ name ] 
      WHERE [ name ] . [ name ] . [ name ]
    ), lex(input))
  end
  
  def test_lex
    assert_equal %w({ }), lex("{}")
    assert_equal %w([ name ]), lex('[Time]')
    assert_equal %w([ name ] . [ name ]), lex('[Time].[1997]')
    assert_equal %w({ [ name ] . [ name ] }), lex('{[Time].[1997]}')
    assert_equal %w({ [ name ] . [ name name ] , [ name ] . [ name name ] }), 
      lex('{[Measures].[Unit Sales],[Measures].[Store Sales]}'
    )
    assert_equal %w(SELECT { [ name ] . [ name name ] , [ name ] . [ name name ] } ON COLUMNS , ),
      lex('SELECT {[Measures].[Unit Sales], [Measures].[Store Sales]} ON COLUMNS,')
    assert_equal %w(FROM [ name ]), lex('FROM [Sales]')
    assert_equal %w(WHERE [ name ] . [ name ] . [ name ]), lex('WHERE [Time].[1997].[Q2]')
  end
  
  def lex(q)
    MDXLexer.lex(q).collect { |t| t.symbol_name }.delete_if { |t| t == Dhaka::END_SYMBOL_NAME }
  end
end