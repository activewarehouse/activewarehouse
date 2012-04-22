file = open('activerecord.log', 'w')
ActiveRecord::Base.logger = Logger.new(file)
ActiveRecord::Base.logger.level = Logger::DEBUG

ActiveRecord::Base.configurations = {
  'awunit' => {
    :adapter  => 'mysql',
    :username => 'root',
    :database => 'activewarehouse_unittest',
    :password => '',
    :host => 'localhost',
  },
}

ActiveRecord::Base.establish_connection 'awunit'

ActiveRecord::Base.connection.initialize_schema_migrations_table
