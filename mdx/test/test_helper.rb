$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'test/unit'

require 'mdx_grammar'
require 'mdx_parser'
require 'mdx_lexer_specification'
require 'mdx_lexer'
require 'mdx_evaluator'
require 'pp'