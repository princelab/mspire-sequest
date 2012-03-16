
module Mspire
  module Sequest
    VERSION = File.open(File.dirname(__FILE__) + '/../../VERSION') {|io| io.gets.chomp }
  end
end
