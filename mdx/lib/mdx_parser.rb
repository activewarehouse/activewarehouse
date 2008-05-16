class MDXParser < Dhaka::CompiledParser

  self.grammar = MDXGrammar

  start_with 0

  at_state(22) {
    for_symbols("SELECT", ")") { reduce_with "mdx_expression_properties" }
  }

  at_state(40) {
    for_symbols("_End_", ")") { reduce_with "single_slice_with_parens" }
  }

  at_state(52) {
    for_symbols("FROM", "_End_", "WHERE") { reduce_with "select_all" }
  }

  at_state(32) {
    for_symbols("FROM") { shift_to 33 }
  }

  at_state(72) {
    for_symbols("SetExpression") { shift_to 53 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("Select") { shift_to 51 }
    for_symbols("[") { shift_to 9 }
    for_symbols("From") { shift_to 73 }
    for_symbols("*") { shift_to 52 }
    for_symbols("TupleExpression") { shift_to 61 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
    for_symbols("SelectSubcubeClause") { shift_to 35 }
    for_symbols("SelectQueryAxisClause") { shift_to 60 }
    for_symbols("Clause") { shift_to 31 }
  }

  at_state(43) {
    for_symbols("_End_", ")") { reduce_with "multiple_slice_with_parens" }
  }

  at_state(19) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("SetExpression") { shift_to 22 }
    for_symbols("{") { shift_to 23 }
    for_symbols("name") { shift_to 18 }
    for_symbols("MDXExpression") { shift_to 20 }
  }

  at_state(26) {
    for_symbols(",") { shift_to 27 }
    for_symbols("SELECT", "}", ")", "ON") { reduce_with "single_tuple_expression" }
  }

  at_state(28) {
    for_symbols("SELECT", "}", ")", "ON") { reduce_with "multiple_tuple_expression" }
  }

  at_state(33) {
    for_symbols("SetExpression") { shift_to 53 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("Select") { shift_to 51 }
    for_symbols("[") { shift_to 9 }
    for_symbols("*") { shift_to 52 }
    for_symbols("TupleExpression") { shift_to 61 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
    for_symbols("SelectSubcubeClause") { shift_to 35 }
    for_symbols("SelectQueryAxisClause") { shift_to 60 }
    for_symbols("Clause") { shift_to 31 }
    for_symbols("From") { shift_to 34 }
  }

  at_state(18) {
    for_symbols("Name") { shift_to 7 }
    for_symbols("name") { shift_to 6 }
    for_symbols("(") { shift_to 19 }
    for_symbols(",", ".", "SELECT", ")") { reduce_with "name_part" }
  }

  at_state(71) {
    for_symbols("FROM") { shift_to 72 }
  }

  at_state(49) {
    for_symbols("SelectCellPropertyListClause") { shift_to 50 }
    for_symbols("_End_") { reduce_with "slicer" }
  }

  at_state(50) {
    for_symbols("_End_") { reduce_with "slicer_and_cell_property_list" }
  }

  at_state(48) {
    for_symbols("_End_") { reduce_with "cell_property_list" }
  }

  at_state(42) {
    for_symbols(")") { shift_to 43 }
  }

  at_state(20) {
    for_symbols(")") { shift_to 21 }
  }

  at_state(27) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("SetExpression") { shift_to 28 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
  }

  at_state(58) {
    for_symbols(",", "FROM", "_End_", "WHERE") { reduce_with "on_columns" }
  }

  at_state(34) {
    for_symbols("_End_") { reduce_with "with_select_from" }
  }

  at_state(25) {
    for_symbols("SELECT", "}", ")", "ON") { reduce_with "set_expression_with_braces" }
  }

  at_state(35) {
    for_symbols("SelectSlicerAxisClause") { shift_to 49 }
    for_symbols("_End_") { reduce_with "select_subcube_clause" }
    for_symbols("SelectCellPropertyListClause") { shift_to 48 }
    for_symbols("WHERE") { shift_to 37 }
    for_symbols("FromOptions") { shift_to 36 }
  }

  at_state(70) {
    for_symbols("SetExpression") { shift_to 53 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("Select") { shift_to 71 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("*") { shift_to 52 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
    for_symbols("SelectQueryAxisClause") { shift_to 60 }
    for_symbols("Clause") { shift_to 31 }
  }

  at_state(2) {
    for_symbols("MEMBER") { shift_to 3 }
  }

  at_state(51) {
    for_symbols("_End_", "WHERE") { reduce_with "subcube_clause" }
  }

  at_state(65) {
    for_symbols("SELECT") { reduce_with "member" }
  }

  at_state(24) {
    for_symbols("}") { shift_to 25 }
  }

  at_state(37) {
    for_symbols("TupleExpression") { shift_to 44 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("SlicerSpecification") { shift_to 47 }
    for_symbols("[") { shift_to 9 }
    for_symbols("(") { shift_to 38 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(67) {
    for_symbols("CreateCellCalculationBodyClause") { shift_to 68 }
  }

  at_state(41) {
    for_symbols("TupleExpression") { shift_to 44 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("SlicerSpecification") { shift_to 42 }
    for_symbols("[") { shift_to 9 }
    for_symbols("(") { shift_to 38 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(23) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("SetExpression") { shift_to 24 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
  }

  at_state(62) {
    for_symbols("CreateSetBodyClause") { shift_to 63 }
  }

  at_state(45) {
    for_symbols("TupleExpression") { shift_to 44 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("(") { shift_to 38 }
    for_symbols("SlicerSpecification") { shift_to 46 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(4) {
    for_symbols(",", "SELECT", "_End_", "AS", "WHERE", "}", ")", "ON") { reduce_with "single_part" }
    for_symbols(".") { shift_to 5 }
  }

  at_state(55) {
    for_symbols("SetExpression") { shift_to 53 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
    for_symbols("Clause") { shift_to 56 }
  }

  at_state(47) {
    for_symbols("_End_") { reduce_with "where" }
  }

  at_state(12) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("TupleExpression") { shift_to 13 }
    for_symbols("[") { shift_to 9 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(38) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 39 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(39) {
    for_symbols(")") { shift_to 40 }
    for_symbols(",") { shift_to 41 }
  }

  at_state(14) {
    for_symbols("SELECT") { reduce_with "calculated_member" }
  }

  at_state(68) {
    for_symbols("SELECT") { reduce_with "cell_calculation" }
  }

  at_state(46) {
    for_symbols("_End_", ")") { reduce_with "multiple_slice" }
  }

  at_state(56) {
    for_symbols("FROM", "_End_", "WHERE") { reduce_with "recursive_clause" }
  }

  at_state(36) {
    for_symbols("_End_") { reduce_with "select_subcube_clause_with_where" }
  }

  at_state(1) {
    for_symbols("CELL") { shift_to 66 }
    for_symbols("SET") { shift_to 62 }
    for_symbols("SelectWithClause") { shift_to 29 }
    for_symbols("CALCULATED") { shift_to 2 }
    for_symbols("MEMBER") { shift_to 64 }
  }

  at_state(13) {
    for_symbols(",", "SELECT", "_End_", "AS", "WHERE", "}", ")", "ON") { reduce_with "multiple_part_with_brackets" }
  }

  at_state(64) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("TupleExpression") { shift_to 15 }
    for_symbols("[") { shift_to 9 }
    for_symbols("CreateMemberBodyClause") { shift_to 65 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(3) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("TupleExpression") { shift_to 15 }
    for_symbols("[") { shift_to 9 }
    for_symbols("CreateMemberBodyClause") { shift_to 14 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(5) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 8 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(31) {
    for_symbols("FROM", "_End_", "WHERE") { reduce_with "clause_single" }
  }

  at_state(29) {
    for_symbols("SELECT") { shift_to 30 }
  }

  at_state(15) {
    for_symbols("AS") { shift_to 16 }
    for_symbols("SELECT") { reduce_with "member_body_clause" }
  }

  at_state(59) {
    for_symbols(",", "FROM", "_End_", "WHERE") { reduce_with "on_rows" }
  }

  at_state(8) {
    for_symbols(",", "SELECT", "_End_", "AS", "WHERE", "}", ")", "ON") { reduce_with "multiple_part" }
  }

  at_state(61) {
    for_symbols(",") { shift_to 27 }
    for_symbols("ON") { reduce_with "single_tuple_expression" }
    for_symbols("_End_", "WHERE") { reduce_with "cube_name" }
  }

  at_state(66) {
    for_symbols("CALCULATION") { shift_to 67 }
  }

  at_state(16) {
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("MDXExpression") { shift_to 17 }
    for_symbols("SetExpression") { shift_to 22 }
    for_symbols("{") { shift_to 23 }
    for_symbols("name") { shift_to 18 }
  }

  at_state(6) {
    for_symbols("Name") { shift_to 7 }
    for_symbols("name") { shift_to 6 }
    for_symbols(",", ".", "SELECT", "_End_", "AS", "]", "WHERE", "}", "ON", ")") { reduce_with "name_part" }
  }

  at_state(30) {
    for_symbols("SetExpression") { shift_to 53 }
    for_symbols("Name") { shift_to 4 }
    for_symbols("[") { shift_to 9 }
    for_symbols("TupleExpression") { shift_to 26 }
    for_symbols("*") { shift_to 52 }
    for_symbols("name") { shift_to 6 }
    for_symbols("{") { shift_to 23 }
    for_symbols("Select") { shift_to 32 }
    for_symbols("SelectQueryAxisClause") { shift_to 60 }
    for_symbols("Clause") { shift_to 31 }
  }

  at_state(0) {
    for_symbols("SELECT") { shift_to 70 }
    for_symbols("statement") { shift_to 69 }
    for_symbols("WITH") { shift_to 1 }
  }

  at_state(63) {
    for_symbols("SELECT") { reduce_with "set_clause" }
  }

  at_state(73) {
    for_symbols("_End_") { reduce_with "select_from" }
  }

  at_state(7) {
    for_symbols(",", ".", "SELECT", "_End_", "AS", "]", "WHERE", "}", "ON", ")") { reduce_with "multiple_name_part" }
  }

  at_state(60) {
    for_symbols("FROM", "_End_", "WHERE") { reduce_with "select_query_axis_clause" }
  }

  at_state(69) {
    for_symbols("_End_") { reduce_with "expression" }
  }

  at_state(53) {
    for_symbols("OnClause") { shift_to 54 }
    for_symbols("ON") { shift_to 57 }
  }

  at_state(54) {
    for_symbols("FROM", "_End_", "WHERE") { reduce_with "clause" }
    for_symbols(",") { shift_to 55 }
  }

  at_state(17) {
    for_symbols("SELECT") { reduce_with "member_body_clause_as" }
  }

  at_state(44) {
    for_symbols(",") { shift_to 45 }
    for_symbols("_End_", ")") { reduce_with "single_slice" }
  }

  at_state(9) {
    for_symbols("Name") { shift_to 10 }
    for_symbols("name") { shift_to 6 }
  }

  at_state(10) {
    for_symbols("]") { shift_to 11 }
  }

  at_state(11) {
    for_symbols(".") { shift_to 12 }
    for_symbols(",", "SELECT", "_End_", "AS", "WHERE", "}", ")", "ON") { reduce_with "single_part_with_brackets" }
  }

  at_state(21) {
    for_symbols("SELECT", ")") { reduce_with "mdx_expression_function" }
  }

  at_state(57) {
    for_symbols("COLUMNS") { shift_to 58 }
    for_symbols("ROWS") { shift_to 59 }
  }

end