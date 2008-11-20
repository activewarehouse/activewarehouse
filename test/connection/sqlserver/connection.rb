file = open('activerecord.log', 'w')
ActiveRecord::Base.logger = Logger.new(file)
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.configurations = {
  'awunit' => {
    :adapter  => 'sqlserver',
    :host     => 'localhost',
    :username => 'sa',
    :password => 'qq',
    :database => 'activewarehouse_unittest',
  },
}

ActiveRecord::Base.establish_connection 'awunit'