require 'rubygems'
require 'dhaka'

class MDXLexerSpecification < Dhaka::LexerSpecification
  KEYWORDS = File.readlines(File.dirname(__FILE__) + '/keywords.txt').collect { |w| w.strip }
  
  %w| ( ) [ ] . { } + * / ^ |.each do |char|
    for_pattern("\\#{char}") do
      create_token(char)
    end
  end
  
  %w| , - : < <= <> = > >= |.each do |char|
    for_pattern(char) do
      create_token(char)
    end
  end
  
  %w| AND IS NOT OR XOR |.each do |operator|
    for_pattern(operator) do
      create_token(operator)
    end
  end
  
  for_pattern('(\w|_|\d)+') do
    if KEYWORDS.include?(current_lexeme.value)
      create_token current_lexeme.value
    else
      create_token 'name'
    end
  end
  
  for_pattern('\s+') do
    # ignore whitespace
  end
end

lexer = Dhaka::Lexer.new(MDXLexerSpecification)
File.open(File.dirname(__FILE__) + '/mdx_lexer.rb', 'w') do |file| 
  file << lexer.compile_to_ruby_source_as(:MDXLexer)
end