require 'rspec'
require 'ms/testdata'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation  # :progress, :html, :textmate
  #config.formatter = :progress # :progress, :html, :textmate
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

TESTFILES = File.dirname(__FILE__) + '/testfiles'
SEQUEST_DIR = MS::TESTDATA + '/sequest' 
