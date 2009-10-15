#!/usr/bin/ruby


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

