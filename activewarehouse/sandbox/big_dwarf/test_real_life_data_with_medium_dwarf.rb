require 'pp'
require 'test/unit/assertions'
require 'medium_dwarf'
require 'profiler'
include Test::Unit::Assertions

dwarf = nil

#dwarf = DwarfBuilder.new('/home/sladd/work/camber/queryoutput2', "\t", 5, 1).process
#File.open('dwarf.export2', 'w'){|f| Marshal.dump(dwarf, f)}
#pp dwarf

File.open('dwarf.export2') {|f| dwarf = Marshal.load(f)}
dimension_names = %w[service_branch_class person_class fiscal_year calendar_month day_in_month]
fact_names = %w[cost]

query = RowColumnBlockQuery.new(dwarf, dimension_names, fact_names)

pp query.query('person_class', 'fiscal_year')

puts "Everything worked!"