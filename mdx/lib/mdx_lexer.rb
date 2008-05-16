class MDXLexer < Dhaka::CompiledLexer

  self.specification = MDXLexerSpecification

  start_with 31703150

  at_state(31584870) {
    recognize(":")
  }

  at_state(31585550) {
    recognize("\\{")
  }

  at_state(31597330) {
    recognize("(\\w|_|\\d)+")
    for_characters("S") { switch_to 31596920 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31696840) {
    recognize("(\\w|_|\\d)+")
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31701820) {
    recognize(">")
    for_characters("=") { switch_to 31701320 }
  }

  at_state(31582580) {
    recognize("\\}")
  }

  at_state(31584560) {
    recognize("\\[")
  }

  at_state(31703150) {
    for_characters("\t", "\n", " ") { switch_to 31699640 }
    for_characters("O") { switch_to 31615930 }
    for_characters("-") { switch_to 31700460 }
    for_characters("N") { switch_to 31645570 }
    for_characters(")") { switch_to 31669660 }
    for_characters("I") { switch_to 31597330 }
    for_characters("<") { switch_to 31583800 }
    for_characters("A") { switch_to 31668220 }
    for_characters("]") { switch_to 31582310 }
    for_characters("[") { switch_to 31584560 }
    for_characters("}") { switch_to 31582580 }
    for_characters("{") { switch_to 31585550 }
    for_characters(",") { switch_to 31697750 }
    for_characters(">") { switch_to 31701820 }
    for_characters("^") { switch_to 31698190 }
    for_characters(".") { switch_to 31585210 }
    for_characters("(") { switch_to 31700050 }
    for_characters("=") { switch_to 31700870 }
    for_characters("*") { switch_to 31582840 }
    for_characters(":") { switch_to 31584870 }
    for_characters("X") { switch_to 31697340 }
    for_characters("+") { switch_to 31584150 }
    for_characters("/") { switch_to 31698600 }
    for_characters("J", "o", "8", "p", "9", "K", "_", "q", "L", "r", "M", "s", "t", "a", "u", "P", "b", "Q", "c", "v", "R", "d", "w", "S", "e", "x", "T", "f", "y", "U", "g", "0", "z", "B", "h", "1", "C", "V", "i", "2", "D", "W", "j", "3", "E", "4", "F", "Y", "k", "5", "G", "Z", "l", "H", "m", "6", "n", "7") { switch_to 31696840 }
  }

  at_state(31635810) {
    recognize("NOT")
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31665250) {
    recognize("(\\w|_|\\d)+")
    for_characters("D") { switch_to 31661580 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31582840) {
    recognize("\\*")
  }

  at_state(31585210) {
    recognize("\\.")
  }

  at_state(31615930) {
    recognize("(\\w|_|\\d)+")
    for_characters("R") { switch_to 31608480 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31661580) {
    recognize("AND")
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31698600) {
    recognize("\\/")
  }

  at_state(31700870) {
    recognize("=")
  }

  at_state(31583110) {
    recognize("<>")
  }

  at_state(31697340) {
    recognize("(\\w|_|\\d)+")
    for_characters("O") { switch_to 31686850 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31699640) {
    recognize("\\s+")
    for_characters(" ", "\t", "\n") { switch_to 31699640 }
  }

  at_state(31582310) {
    recognize("\\]")
  }

  at_state(31645570) {
    recognize("(\\w|_|\\d)+")
    for_characters("O") { switch_to 31642170 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31668220) {
    recognize("(\\w|_|\\d)+")
    for_characters("N") { switch_to 31665250 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31686850) {
    recognize("(\\w|_|\\d)+")
    for_characters("R") { switch_to 31681670 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31583800) {
    recognize("<")
    for_characters("=") { switch_to 31583420 }
    for_characters(">") { switch_to 31583110 }
  }

  at_state(31584150) {
    recognize("\\+")
  }

  at_state(31642170) {
    recognize("(\\w|_|\\d)+")
    for_characters("T") { switch_to 31635810 }
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31700050) {
    recognize("\\(")
  }

  at_state(31700460) {
    recognize("-")
  }

  at_state(31596920) {
    recognize("IS")
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31697750) {
    recognize(",")
  }

  at_state(31698190) {
    recognize("\\^")
  }

  at_state(31608480) {
    recognize("OR")
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31669660) {
    recognize("\\)")
  }

  at_state(31681670) {
    recognize("XOR")
    for_characters("K", "V", "k", "v", "6", "W", "A", "L", "w", "l", "7", "a", "8", "M", "b", "B", "X", "m", "x", "9", "Y", "C", "N", "y", "c", "n", "O", "D", "Z", "o", "d", "z", "E", "P", "e", "p", "0", "1", "Q", "F", "q", "f", "2", "G", "R", "g", "r", "S", "H", "s", "h", "3", "i", "t", "_", "4", "I", "T", "5", "U", "J", "u", "j") { switch_to 31696840 }
  }

  at_state(31701320) {
    recognize(">=")
  }

  at_state(31583420) {
    recognize("<=")
  }

end