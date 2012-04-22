def declare_gems(activerecord_version)
  source :rubygems

  gem 'adapter_extensions', :git => 'git://github.com/activewarehouse/adapter_extensions.git'
  gem 'activewarehouse-etl', :git => 'git://github.com/activewarehouse/activewarehouse-etl.git'

  gem 'activerecord', activerecord_version

  if activerecord_version < '3.1'
    gem 'mysql2', '< 0.3'
  else
    # use our own fork for bulk load support until issue fixed:
    # https://github.com/brianmario/mysql2/pull/242
    gem 'mysql2', :git => 'https://github.com/activewarehouse/mysql2.git'
  end

  gem 'mysql'

  gem 'pg'
  gem 'rspec'
  
  gem 'awesome_print'
  gem 'rake'
  gem 'flexmock'
  gem 'shoulda', '3.0.1'
  gem 'sqlite3'

  gem 'spreadsheet'
  gem 'nokogiri'
  gem 'fastercsv'

  gem 'standalone_migrations'
end