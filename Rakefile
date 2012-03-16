require 'rubygems'
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "ms-sequest"
  gem.homepage = "http://github.com/jtprince/ms-sequest"
  gem.license = "MIT"
  gem.summary = %Q{An mspire library supporting SEQUEST, Bioworks, SQT, etc}
  gem.description = %Q{reads .SRF, .SQT and supports conversions}
  gem.email = "jtprince@gmail.com"
  gem.authors = ["John T. Prince"]
  gem.rubyforge_project = 'mspire'
  gem.add_runtime_dependency "mspire", "~> 0.7.2"
  #gem.add_runtime_dependency "ms-core", ">= 0.0.17"
  #gem.add_runtime_dependency "ms-msrun", ">= 0.3.4"
  gem.add_runtime_dependency "trollop", "~> 1.16"
  gem.add_development_dependency "jeweler", "~> 1.5.2"
  gem.add_development_dependency "bio", "~> 1.4.2"
  gem.add_development_dependency "ms-testdata", ">= 0.2.1"
  gem.add_development_dependency "spec-more", ">= 0"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

#require 'rcov/rcovtask'
#Rcov::RcovTask.new do |spec|
#  spec.libs << 'spec'
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.verbose = true
#end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ms-sequest #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end










