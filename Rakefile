require 'rubygems'
require 'rake'
require 'jeweler'
require 'rake/testtask'
require 'rcov/rcovtask'

NAME = "ms-sequest"

gemspec = Gem::Specification.new do |s|
  s.name = NAME
  s.authors = ["John T. Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "http://github.com/jtprince/" + NAME
  s.summary = "An mspire library supporting SEQUEST, Bioworks, SQT, etc"
  s.description = "reads .SRF, .SQT and supports conversions"
  s.rubyforge_project = 'mspire'

  s.add_dependency("arrayclass", ">= 0.1.0")
  s.add_dependency("ms-core", ">= 0.0.2")
  s.add_dependency("ms-fasta", ">= 0.4.1")

  s.add_development_dependency("ms-testdata", ">= 0.18.0")
  s.add_development_dependency("spec-more")
end
Jeweler::Tasks.new(gemspec)

Rake::TestTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
  unless ENV['gems']
    t.libs << 'submodule/ms-testdata/lib'
    #t.libs << 'submodule/ms-in_silico/lib'
    #t.libs << 'submodule/tap-mechanize/lib'
  end
end

Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

task :default => :spec

