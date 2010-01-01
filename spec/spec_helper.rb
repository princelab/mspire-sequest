
require 'rubygems'
require 'spec/more'

# This is already defined in our module
#TESTFILES = File.expand_path(File.dirname(__FILE__)) + '/testfiles'

Bacon.summary_on_exit

#module Bacon
#  class Context
#    def hash_match(hash, obj)
#      hash.each do |k,v|
#        if v.is_a?(Hash)
#          hash_match(v, obj.send(k.to_sym))
#        else
#          puts "#{k}: #{v} but was #{obj.send(k.to_sym)}" if obj.send(k.to_sym) != v
#          obj.send(k.to_sym).should.equal v
#        end
#      end
#    end
#  end
#end


TESTFILES = File.expand_path(File.dirname(__FILE__)) + "/testfiles"

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

def capture_stderr
  begin
    $stderr = StringIO.new
    yield
    $stderr.rewind && $stderr.read
  ensure
    $stderr = STDERR
  end
end

