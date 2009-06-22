require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

NAME = 'ms-sequest'
EXTRA_RDOC_FILES = %w(README MIT-LICENSE History)
LIB_FILES = Dir["lib/**/*.rb"]

DIST_FILES =  LIB_FILES + EXTRA_RDOC_FILES

LEAVE_OUT = %w(lib/ms/sequest/bioworks.rb lib/ms/sequest/pepxml.rb)

require "lib/ms/sequest"  # to get the Version #

gemspec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = Ms::Sequest::VERSION
  s.authors = ["John Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "http://mspire.rubyforge.org/projects/#{NAME}/"
  s.platform = Gem::Platform::RUBY
  s.summary = "An mspire library supporting SEQUEST, Bioworks, SQT, etc"
  s.description = "reads .SRF, .SQT and supports conversions"
  s.require_path = "lib"
  s.rubyforge_project = "mspire"
  s.has_rdoc = true
  s.executables = Dir["bin/*"].map {|v| v.sub(/^bin\//,'') }
  s.add_dependency("arrayclass", ">= 0.1.0")
  s.add_dependency("ms-core", ">= 0.0.1")
  s.add_dependency("tap", ">= 0.17.1")
  s.add_dependency("ms-fasta", ">= 0.2.3")
  #s.add_dependency("tap", ">= 0.12.4")
  #s.add_dependency("tap-mechanize", ">= 0.5.1")
  #s.add_dependency("external", ">= 0.3.0")
  #s.add_dependency("ms-in_silico", ">= 0.2.3")
  s.rdoc_options.concat %W{--main README -S -N --title Ms-Sequest}
  
  # list extra rdoc files like README here.
  s.extra_rdoc_files = EXTRA_RDOC_FILES
  s.files = DIST_FILES - LEAVE_OUT
end

desc "the files going to be in the gem"
task :files do
  puts "FILES in GEM:"
  puts "  " + gemspec.files.join("\n")
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end

desc 'Prints the gemspec manifest.'
task :print_manifest do
  # collect files from the gemspec, labeling 
  # with true or false corresponding to the
  # file existing or not
  files = gemspec.files.inject({}) do |files, file|
    files[File.expand_path(file)] = [File.exists?(file), file]
    files
  end
  
  # gather non-rdoc/pkg files for the project
  # and add to the files list if they are not
  # included already (marking by the absence
  # of a label)
  Dir.glob("**/*").each do |file|
    next if file =~ /^(rdoc|pkg|backup|config|submodule|spec)/ || File.directory?(file)
    
    path = File.expand_path(file)
    files[path] = ["", file] unless files.has_key?(path)
  end
  
  # sort and output the results
  files.values.sort_by {|exists, file| file }.each do |entry| 
    puts "%-5s %s" % entry
  end
end

#
# Documentation tasks
#

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  spec = gemspec
  
  rdoc.rdoc_dir = 'rdoc'
  rdoc.rdoc_files.include( spec.extra_rdoc_files )
  rdoc.rdoc_files.include( spec.files.select {|file| file =~ /^lib.*\.rb$/} )
  
  require 'cdoc'
  rdoc.template = 'cdoc/cdoc_html_template' 
  rdoc.options << '--fmt' << 'cdoc'
end

desc "Publish RDoc to RubyForge"
task :publish_rdoc => [:rdoc] do
  require 'yaml'
  
  config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  host = "#{config["username"]}@rubyforge.org"
  
  rsync_args = "-v -c -r"
  remote_dir = "/var/www/gforge-projects/mspire/projects/ms-sequest"
  local_dir = "rdoc"
 
  sh %{rsync #{rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
end


#
# Test tasks
#

desc 'Default: Run specs.'
task :default => :spec

desc 'Run specs.'
Rake::TestTask.new(:spec) do |t|
  # can specify SPEC=<file>_spec.rb or TEST=<file>_spec.rb
  ENV['TEST'] = ENV['SPEC'] if ENV['SPEC']  
  t.libs = ['lib']
  t.test_files = Dir.glob( File.join('spec', ENV['pattern'] || '**/*_spec.rb') )
  unless ENV['gems']
    t.libs << 'submodule/ms-testdata/lib'
    #t.libs << 'submodule/ms-in_silico/lib'
    #t.libs << 'submodule/tap-mechanize/lib'
  end
  t.verbose = true
  t.warning = true
end


