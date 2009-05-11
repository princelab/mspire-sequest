require 'rubygems'
require 'minitest/spec'
require 'tap'
require 'tap/spec'

class Class
  def xit(name, &block)
  end
end unless Class.respond_to?(:xit)

begin
  require 'ms/testdata'
rescue(LoadError)
  puts %Q{
Tests probably cannot be run because the submodules have
not been initialized. Use these commands and try again:
 
% git submodule init
% git submodule update
 
}
  raise
end
