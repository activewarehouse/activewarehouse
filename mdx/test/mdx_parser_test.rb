require File.dirname(__FILE__) + '/test_helper'

class MDXParserTest < Test::Unit::TestCase
  def assert_parsable(q)
    result = MDXParser.parse(MDXLexer.lex(q))
    pp result if result.has_error?
    assert !result.has_error?, "Failed to parse #{q}"
    result
  end
  
  def test_query
    q = "SELECT date.calendar.calendar_month ON COLUMNS FROM orders"
    assert_parsable(q)
    
    q = "WITH CALCULATED MEMBER date.calendar.first8months2003 
SELECT date.calendar.calendar_year ON COLUMNS, product.category.children ON ROWS
FROM orders"
    assert_parsable(q)

    q = "WITH MEMBER date.calendar.first8months2003 
SELECT date.calendar.calendar_year ON COLUMNS, product.category.children ON ROWS 
FROM orders WHERE measures.order_quantity"
    assert_parsable(q)
    
    q = "SELECT * FROM orders"
    assert_parsable(q)

    q = "SELECT [Measures].[Unit Sales] ON COLUMNS FROM [Sales]"
    assert_parsable(q)
    
    q = "SELECT Measures.[Unit Sales] ON COLUMNS FROM [Sales Figures]"
    assert_parsable(q)
  end
  
  def test_query3
    q = "SELECT {[Measures].[Unit Sales], [Measures].[Store Sales]} ON COLUMNS,
    {[Product].members} ON ROWS
    FROM [Sales]
    WHERE [Time].[1997].[Q2]"
    assert_parsable(q)
  end
  
  def test_query_4
    q = "
    SELECT 
        [Date].[Calendar].[First8Months2003] ON COLUMNS,
        [Product].[Category].Children ON ROWS
    FROM
        [Adventure Works]
    WHERE
        [Measures].[Order Quantity]"
    assert_parsable(q)
  end
  
  def test_query_6
    q = "
    SELECT 
        [Date].[Calendar].[First8Months2003] ON COLUMNS,
        [Product].[Category].Children ON ROWS
    FROM
        [Adventure Works]
    WHERE
        ([Measures].[Order Quantity], [Measures].All)"
    assert_parsable(q)
  end
  
  def test_query_5
    q = "WITH MEMBER [Date].[Calendar].[First8Months2003] AS
        Aggregate(
            PeriodsToDate(
                [Date].[Calendar].[Calendar Year], 
                [Date].[Calendar].[Month].[August 2003]
            )
        )
        SELECT 
            [Date].[Calendar].[First8Months2003] ON COLUMNS,
            [Product].[Category].Children ON ROWS
        FROM
            [Adventure Works]
        WHERE
            [Measures].[Order Quantity]"
    assert_parsable(q)
  end
end