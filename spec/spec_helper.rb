
require 'rubygems'
require 'spec/more'

Bacon.summary_on_exit

# is this already defined??
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

