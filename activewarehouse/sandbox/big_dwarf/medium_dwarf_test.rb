require 'pp'
require 'test/unit/assertions'
require 'medium_dwarf'
require 'profiler'
include Test::Unit::Assertions

DwarfBuilder.new('head', 10, 3).process