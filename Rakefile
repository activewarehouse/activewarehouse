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
RSpec::Core::RakeTask.new(:core) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
  # unless ENV['NO_RCOV']
  #   spec.rcov = true
  #   spec.rcov_dir = '../doc/output/coverage'
  #   spec.rcov_opts = ['--exclude', 'spec\/spec,bin\/spec,examples,\/var\/lib\/gems,\/Library\/Ruby,\.autotest']
  # end
end
