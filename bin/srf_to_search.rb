#!/usr/bin/env ruby

require 'rubygems'
require 'tap/task'
require 'ms/sequest/srf/search'

if ARGV.size == 0
  ARGV << "--help"
end

task_class = Ms::Sequest::Srf::SrfToSearch

parser = ConfigParser.new do |opts|
  opts.separator "configurations"
  opts.add task_class.configurations
 
  opts.on "--help", "Print this help" do
    puts "usage: #{File.basename(__FILE__)} <file>.srf ..."
    puts
    puts opts
    exit(0)
  end
end

parser.parse!(ARGV)
 
task = task_class.new(parser.config)

ARGV.each do |file|
  task.execute(file)
end


