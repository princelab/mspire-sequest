#!/usr/bin/env ruby

require 'rubygems'
require 'tap/task'
require 'ms/sequest/srf/sqt'

if ARGV.size == 0
  ARGV << "--help"
end

task_class = Ms::Sequest::Srf::Srftosqt
config = ConfigParser.new do |opts|
  opts.separator "configurations"
  opts.add task_class.configurations
 
  opts.on "--help", "Print this help" do
    puts "usage: #{File.basename(__FILE__)} <file>.srf ..."
    puts "outputs: <file>.sqt ..."
    puts
    puts task_class::desc.wrap
    puts
    puts opts
    exit(0)
  end
end

config.parse!(ARGV)
 
task = task_class.new(config)

ARGV.each do |file|
  task.execute(ARGV)
end


