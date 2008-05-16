require 'rubygems'
require 'active_support'
require 'active_record'

file = open('dwarf.log', 'w')
ActiveRecord::Base.logger = Logger.new(file)
ActiveRecord::Base.logger.level = Logger::FATAL
ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.configurations = {
  'dwarf' => {
    :adapter  => 'mysql',
    :username => 'root',
    :database => 'dwarf',
    :password => 'qq',
    #:socket => '/tmp/mysql.sock'
    #:adapter => 'sqlite3',
    #:dbfile => 'db/dwarf.db'
  },
}

ActiveRecord::Base.establish_connection 'dwarf'