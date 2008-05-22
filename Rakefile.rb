# Load rake files for sub-projects
(Dir["#{File.dirname(__FILE__)}/**/Rakefile"] - 
Dir["#{File.dirname(__FILE__)}/rails_warehouse/Rakefile"]).each { |ext| load ext }

require 'date'

namespace :github do
  desc "Update Github Gemspec"
  task :update_gemspec do
    [AW.spec('activewarehouse/'), AWETL.spec('etl/')].each do |spec|
      File.open(File.join(File.dirname(__FILE__), "#{spec.name}.gemspec"), "w"){|f| f << spec.to_ruby}
    end
  end
end

