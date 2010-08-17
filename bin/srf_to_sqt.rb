#!/usr/bin/env ruby

require 'rubygems'
require 'ms/sequest/srf/sqt'

opt = {
  :filter => true
}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [OPTIONS] <file>.srf ..."
  op.separator "output: <file>.sqt ..."
  op.separator ""
  op.separator "options:"
  op.on("-d", "--db-info", "calculates num aa's and md5sum on db") {|v| opt[:db_info] = v }
  op.on("-p", "--db-path <String>", "If you need to specify the database path") {|v| opt[:new_db_path] = v }
  op.on("-u", "--db-update", "update the sqt file to reflect --db_path") {|v| opt[:db_update] = v }
  op.on("-n", "--no-filter", "by default, pephit must be within peptide_mass_tolerance",  "(defined in sequest.params) to be included.  Turns this off.") { opt[:filter] = false }
  op.on("-r", "--round", "round floating point values reasonably") {|v| opt[:round] = v }
end
opts.parse!

if ARGV.size == 0
  puts(opts) || exit
end

ARGV.each do |srf_file|
  base = srf_file.chomp(File.extname(srf_file))
  outfile = base + '.sqt'

  srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => opt.delete(:filter))
  srf.to_sqt(outfile, :db_info => db_info, :new_db_path => db_path, :update_db_path => db_update, :round => round)
end



