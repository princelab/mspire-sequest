require 'rubygems'
require 'ms/testdata'
require 'spec/more'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

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


Bacon.summary_on_exit
