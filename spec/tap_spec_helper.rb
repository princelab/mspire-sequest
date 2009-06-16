require 'rubygems'
require 'minitest/spec'
require 'tap'
require 'tap/test'

MiniTest::Unit.autorun

class Class
  def xit(name, &block)
  end
end unless Class.respond_to?(:xit)

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


module Shareable

  def before(type = :each, &block)
    raise "unsupported before type: #{type}" unless type == :each
    define_method :setup, &block
  end

  def after(type = :each, &block)
    raise "unsupported after type: #{type}" unless type == :each
    define_method :teardown, &block
  end

  def it desc, &block
    define_method "test_#{desc.gsub(/\W+/, '_').downcase}", &block
  end

  def xit desc, &block
    puts "**Skipping: #{desc}"
    define_method "test_#{desc.gsub(/\W+/, '_').downcase}", lambda {print "s" }
  end

end


