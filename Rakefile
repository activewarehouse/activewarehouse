require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake'
require 'rake/testtask'
require "rspec/core/rake_task" 

desc 'Default: run tests and specs.'
task :default => [:test, :spec]

desc 'Test the active_warehouse plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
  # unless ENV['NO_RCOV']
  #   spec.rcov = true
  #   spec.rcov_dir = '../doc/output/coverage'
  #   spec.rcov_opts = ['--exclude', 'spec\/spec,bin\/spec,examples,\/var\/lib\/gems,\/Library\/Ruby,\.autotest']
  # end
end

def system!(cmd)
  puts cmd
  raise "Command failed!" unless system(cmd)
end

require 'tasks/standalone_migrations'

# experimental tasks to reproduce the Travis behaviour locally
namespace :ci do

  desc "For current RVM, run the tests for one db and one gemfile"
  task :run_one, :db, :gemfile do |t, args|
    ENV['BUNDLE_GEMFILE'] = File.expand_path(args[:gemfile] || (File.dirname(__FILE__) + '/test/config/gemfiles/Gemfile.rails-3.2.x'))
    ENV['DB'] = args[:db] || 'mysql'
    system! "bundle install"
    system! "bundle exec rake db:create"
    system! "bundle exec rake db:create RAILS_ENV=etl_execution"
    system! "bundle exec rake db:migrate"
    system! "bundle exec rake"
  end

  desc "For current RVM, run the tests for all the combination in travis configuration"
  task :run_matrix do
    require 'cartesian'
    config = YAML.load_file('.travis.yml')
    config['env'].cartesian(config['gemfile']).each do |*x|
      env, gemfile = *x.flatten
      db = env.gsub('DB=', '')
      print [db, gemfile].inspect.ljust(40) + ": "
      cmd = "rake \"ci:run_one[#{db},#{gemfile}]\""
      result = system "#{cmd} > /dev/null 2>&1"
      result = result ? "OK" : "FAILED! - re-run with: #{cmd}"
      puts result
    end
  end

end
