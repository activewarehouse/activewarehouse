# Load rake files for sub-projects
Dir["#{File.dirname(__FILE__)}/**/Rakefile"].each { |ext| load ext }

require 'date'

namespace :github do
  desc "Update Github Gemspec"
  task :update_gemspec do
    spec = AW.spec('activewarehouse/')
    File.open(File.join(File.dirname(__FILE__), "#{spec.name}.gemspec"), "w"){|f| f << spec.to_ruby}
  end
end

