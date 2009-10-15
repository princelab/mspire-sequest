#!/usr/bin/ruby

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <file>.fasta ..."
  puts "outputs: <file>_NCBI.fasta ..."
  puts ""
  puts "(Bioworks 3.3.1 [maybe others] does not seem to read an IPI"
  puts "formatted fasta database header lines.  This will change an" 
  puts "IPI format to an NCBI style format that Bioworks can read."
  exit
end

ARGV.each do |file|
  base = file.chomp(File.extname(file))
  outfile = base + '_NCBI' + ".fasta"
  File.open(outfile, 'w') do |out|
    IO.foreach(file) do |line|
      if line =~ /^>/
        (codes, *description) = line[1..-1].split(" ")
        description = description.join(" ")
        code_section = codes.split('|').map {|code| (key, val) = code.split(':') ; "#{key}|#{val}|" }.join
        out.puts ">#{code_section} #{description}"   
      else
        out.print line
      end
    end
  end
end

