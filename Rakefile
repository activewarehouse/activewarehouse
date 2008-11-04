require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'spec/version'
require 'spec/rake/spectask'

require File.join(File.dirname(__FILE__), 'lib/active_warehouse', 'version')

module AW
  PKG_BUILD       = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
  PKG_NAME        = 'activewarehouse'
  PKG_VERSION     = ActiveWarehouse::VERSION::STRING + PKG_BUILD
  PKG_FILE_NAME   = "#{PKG_NAME}-#{PKG_VERSION}"
  PKG_DESTINATION = ENV["PKG_DESTINATION"] || "../#{PKG_NAME}"
end

desc 'Default: run tests and specs.'
task :default => [:test, :spec]

desc 'Test the active_warehouse plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--options', 'spec/spec.opts']
  unless ENV['NO_RCOV']
    t.rcov = true
    t.rcov_dir = '../doc/output/coverage'
    t.rcov_opts = ['--exclude', 'spec\/spec,bin\/spec,examples,\/var\/lib\/gems,\/Library\/Ruby,\.autotest']
  end
end

namespace :rcov do
  desc 'Measures test coverage'
  task :test do
    rm_f 'coverage.data'
    mkdir 'coverage' unless File.exist?('coverage')
    rcov = "rcov --aggregate coverage.data --text-summary -Ilib"
    system("#{rcov} test/*_test.rb")
    system("open coverage/index.html") if PLATFORM['darwin']
  end
end

desc 'Generate documentation for the active_warehouse plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActiveWarehouse'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# Gem Spec
module AW
  def self.package_files(package_prefix)
    FileList[
      "#{package_prefix}[a-zA-Z]*.rb",
      "#{package_prefix}README",
      "#{package_prefix}TODO",
      "#{package_prefix}Rakefile",
      "#{package_prefix}db/**/*",
      "#{package_prefix}doc/**/*",
      "#{package_prefix}generators/**/*", 
      "#{package_prefix}lib/**/*",
      "#{package_prefix}tasks/**/*"
    ] - [ "#{package_prefix}test" ]
  end

  def self.spec(package_prefix = '')
    Gem::Specification.new do |s|
      s.name = 'activewarehouse'
      s.version = AW::PKG_VERSION
      s.summary = "Build data warehouses with Rails."
      s.description = <<-EOF
        ActiveWarehouse extends Rails to provide functionality specific for building data warehouses.
      EOF

      s.add_dependency('rake',                '>= 0.8.3')
      s.add_dependency('fastercsv',           '>= 1.1.0')
      s.add_dependency('activesupport',       '>= 2.1.0')
      s.add_dependency('activerecord',        '>= 2.1.0')
      s.add_dependency('actionpack',          '>= 2.1.0')
      s.add_dependency('rails_sql_views',     '>= 0.1.0')
      s.add_dependency('adapter_extensions',  '>= 0.1.0')

      s.rdoc_options << '--exclude' << '.'
      s.has_rdoc = false

      s.files = package_files(package_prefix).to_a.delete_if {|f| f.include?('.svn')}
      s.require_path = 'lib'

      #s.bindir = "bin" # Use these for applications.
      #s.executables = []
      #s.default_executable = ""

      s.author = "Anthony Eden"
      s.email = "anthonyeden@gmail.com"
      s.homepage = "http://activewarehouse.rubyforge.org"
      s.rubyforge_project = "activewarehouse"
    end
  end
end

Rake::GemPackageTask.new(AW.spec) do |pkg|
  pkg.gem_spec = AW.spec
  pkg.need_tar = true
  pkg.need_zip = true
end

desc "Generate code statistics"
task :lines do
  lines, codelines, total_lines, total_codelines = 0, 0, 0, 0

  for file_name in FileList["lib/**/*.rb"]
    next if file_name =~ /vendor/
    f = File.open(file_name)

    while line = f.gets
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
    puts "L: #{sprintf("%4d", lines)}, LOC #{sprintf("%4d", codelines)} | #{file_name}"

    total_lines     += lines
    total_codelines += codelines

    lines, codelines = 0, 0
  end

  puts "Total: Lines #{total_lines}, LOC #{total_codelines}"
end

desc "Publish the release files to RubyForge."
task :release => [ :package ] do
  `rubyforge login`

  for ext in %w( gem tgz zip )
    release_command = "rubyforge add_release activewarehouse #{AW::PKG_NAME} 'REL #{AW::PKG_VERSION}' pkg/#{AW::PKG_NAME}-#{AW::PKG_VERSION}.#{ext}"
    puts release_command
    system(release_command)
  end
end

desc "Publish the API documentation"
task :pdoc => [:rdoc] do 
  Rake::SshDirPublisher.new("aeden@rubyforge.org", "/var/www/gforge-projects/activewarehouse/rdoc", "rdoc").upload
end

desc "Reinstall the gem from a local package copy"
task :reinstall => [:package] do
  windows = RUBY_PLATFORM =~ /mswin/
  sudo = windows ? '' : 'sudo'
  gem = windows ? 'gem.bat' : 'gem'
  `#{sudo} #{gem} uninstall #{AW::PKG_NAME} -x`
  `#{sudo} #{gem} install pkg/#{AW::PKG_NAME}-#{AW::PKG_VERSION}`
end
