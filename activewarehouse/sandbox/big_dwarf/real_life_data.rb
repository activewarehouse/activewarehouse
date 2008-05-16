require 'pp'
require 'test/unit/assertions'
require 'big_dwarf'
require 'profiler'
require 'narray'
include Test::Unit::Assertions

root_block = Block.new([:service_branch_class, :person_class, :fiscal_year,
                        :calendar_month, :day_in_month], [:cost])

sql = <<END
select
 p.service_branch_class,
 p.person_class,
 d.fiscal_year,
 d.calendar_month,
 d.day_in_month,
 f.cost
from medical_case_fact f
join person_dimension p on f.person_id = p.id
join date_dimension d on f.begin_care_date_id = d.id
END

sql = sql.gsub("\n", ' ')
cmd = "bcp \"#{sql}\" queryout queryoutput -c -S \"10.0.5.18\" -U \"pandora\" -P \"xxxxx\""

puts "Begin dump: #{Time.now}"
#puts `#{cmd}`
puts "End dump: #{Time.now}"

i = 0
#Profiler__::start_profile
File.foreach('queryoutput') do |line|
  row = line.chomp.split("\t")
  row[5] = row[5].to_i
  root_block.add_tuple(row[0,5], row[5,1])
  i = i + 1
  puts "#{Time.now} - 100000 lines" if i % 100000 == 0
  break if i == 300000
end
#Profiler__::stop_profile
#Profiler__::print_profile($stderr)

#pp root_block

File.open('real_life', 'w'){|f| Marshal.dump(root_block, f)}