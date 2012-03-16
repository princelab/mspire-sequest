require 'spec/more'
require 'ms/testdata'

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
