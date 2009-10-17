#!/usr/bin/ruby

require 'rubygems'
require 'optparse'
require 'ms/sequest/srf/search'

opt = {
  :format => 'mgf'
}

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.srf"
  op.separator "outputs: <file>.mgf"
  op.on("-f", "--format <mgf|dat>", "the output format (default: #{opt[:format]})") {|v| opt[:format] = v }
end

if ARGV.size == 0
  puts opts
  exit
end

format = opt[:format]

ARGV.each do |srf_file|
  base = srf_file.sub(/\.srf$/i, '')
  newfile = 
    case format
    when 'dta'
      base
    when 'mgf'
      base << '.' << format
    end
  srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => false, :read_pephits => false )
  # options just speed up reading since we don't need .out info anyway
  case format
  when 'mgf'
    srf.to_mgf(newfile)
  when 'dta'
    srf.to_dta_files(newfile)
  end
end











=begin

#require 'tap/task'
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

=end
