require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'spec/more'
require 'ms/testdata'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Bacon.summary_on_exit

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
SEQUEST_DIR = Ms::TESTDATA + '/sequest' 


