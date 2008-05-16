require 'connection'
require 'dwarf'

puts "Beginning Load - #{Time.now}"

rows = [['alice', 'honolulu', '2007', 'jan', 1, 2],
#        ,['alice', 'honolulu', '2007', 'feb', 3, 4],
#        ,['alice', 'honolulu', '2006', 'jan', 5, 6]
        ]
#root_node = DwarfBuilder.new(4, 2).from_array(rows)

root_node = DwarfBuilder.new(5, 1).from_file('../queryoutput2', "\t")

puts "Finished Load - #{Time.now}"