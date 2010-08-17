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
