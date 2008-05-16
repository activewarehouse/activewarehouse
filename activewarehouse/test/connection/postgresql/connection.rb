file = open('activerecord.log', 'w')
ActiveRecord::Base.logger = Logger.new(file)
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.configurations = {
  'awunit' => {
    :adapter  => 'postgresql',
    :username => 'postgres',
    :database => 'activewarehouse_unittest',
    :password => 'postgres',
    :host => 'localhost',
  },
}

ActiveRecord::Base.establish_connection 'awunit'