
require 'rubygems'
require 'rake'
require 'jeweler'
require 'rake/testtask'
require 'rcov/rcovtask'

NAME = "ms-sequest"
WEBSITE_BASE = "website"
WEBSITE_OUTPUT = WEBSITE_BASE + "/output"

gemspec = Gem::Specification.new do |s|
  s.name = NAME
  s.authors = ["John T. Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "http://jtprince.github.com/" + NAME
  s.summary = "An mspire library supporting SEQUEST, Bioworks, SQT, etc"
  s.description = "reads .SRF, .SQT and supports conversions"
  s.rubyforge_project = 'mspire'

  s.add_dependency("arrayclass", ">= 0.1.0")
  s.add_dependency("ms-core", ">= 0.0.2")
  s.add_dependency("tap", ">= 0.17.1")
  s.add_dependency("ms-fasta", ">= 0.2.3")

  s.add_development_dependency("ms-testdata", ">= 0.18.0")
  s.add_development_dependency("spec/more")
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


def rdoc_redirect(base_rdoc_output_dir, package_website_page, version)
  content = %Q{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html><head><title>mspire: } + NAME + %Q{rdoc</title>
<meta http-equiv="REFRESH" content="0;url=#{package_website_page}/rdoc/#{version}/">
</head> </html> 
  }
  FileUtils.mkpath(base_rdoc_output_dir)
  File.open("#{base_rdoc_output_dir}/index.html", 'w') {|out| out.print content }
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  base_rdoc_output_dir = WEBSITE_OUTPUT + '/rdoc'
  version = File.read('VERSION')
  rdoc.rdoc_dir = base_rdoc_output_dir + "/#{version}"
  rdoc.title = NAME + ' ' + version
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :create_redirect do
  base_rdoc_output_dir = WEBSITE_OUTPUT + '/rdoc'
  rdoc_redirect(base_rdoc_output_dir, gemspec.homepage,version)
end

task :rdoc => :create_redirect

namespace :website do
  desc "checkout and configure the gh-pages submodule"
  task :init do
    if File.exist?(WEBSITE_OUTPUT + "/.git")
      puts "!! not doing anything, #{WEBSITE_OUTPUT + "/.git"} already exists !!"
    else

      puts "(not sure why this won't work programmatically)"
      puts "################################################"
      puts "[Execute these commands]"
      puts "################################################"
      puts "git submodule init"
      puts "git submodule update"
      puts "pushd #{WEBSITE_OUTPUT}"
      puts "git co --track -b gh-pages origin/gh-pages ;"
      puts "popd"
      puts "################################################"

      # not sure why this won't work!
      #%x{git submodule init}
      #%x{git submodule update}
      #Dir.chdir(WEBSITE_OUTPUT) do
      #  %x{git co --track -b gh-pages origin/gh-pages ;}
      #end
    end
  end
end

task :default => :spec

task :build => :gemspec

# credit: Rakefile modeled after Jeweler's
