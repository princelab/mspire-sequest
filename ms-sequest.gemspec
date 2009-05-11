Gem::Specification.new do |s|
  s.name = "ms-sequest"
  s.version = "0.0.1"
  s.authors = ["John Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "http://mspire.rubyforge.org/projects/ms-sequest/"
  s.platform = Gem::Platform::RUBY
  s.summary = "An mspire library supporting SEQUEST, Bioworks, SQT, etc"
  s.require_path = "lib"
  s.rubyforge_project = "mspire"
  s.has_rdoc = true
  #s.add_dependency("tap", ">= 0.12.4")
  #s.add_dependency("tap-mechanize", ">= 0.5.1")
  #s.add_dependency("external", ">= 0.3.0")
  #s.add_dependency("ms-in_silico", ">= 0.2.3")
  s.rdoc_options.concat %W{--main README -S -N --title Ms-Sequest}
  
  # list extra rdoc files like README here.
  s.extra_rdoc_files = %W{
    README
    MIT-LICENSE
    History
  }
  
  # list the files you want to include here. you can
  # check this manifest using 'rake :print_manifest'
  s.files = %W{
      Rakefile
      lib/ms/bioworks.rb
      lib/ms/sequest.rb
      lib/ms/sequest/params.rb
      lib/ms/sequest/pepxml.rb
      lib/ms/sqt.rb
      lib/ms/srf.rb
      ms-sequest.gemspec
  }
end
