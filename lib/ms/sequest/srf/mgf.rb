require 'ms/mass'

module Ms
  module Sequest
    class Srf

      # Writes an MGF file to given filename or base_name + '.mgf' if no
      # filename given.
      #
      # This mimicks the output of merge.pl from mascot The only difference is
      # that this does not include the "\r\n" that is found after the peak
      # lists, instead, it uses "\n" throughout the file (thinking that this
      # is preferable to mixing newline styles!)
      def to_mgf(filename=nil)
        filename =
          if filename ; filename
          else
            base_name + '.mgf'
          end
        h_plus = Ms::Mass::MASCOT_H_PLUS
        File.open(filename, 'wb') do |out|
          dta_files.zip(index) do |dta, i_ar|
            chrg = dta.charge
            out.print "BEGIN IONS\n"
            out.print "TITLE=#{[base_name, *i_ar].push('dta').join('.')}\n"
            out.print "CHARGE=#{chrg}+\n"
            out.print "PEPMASS=#{(dta.mh+((chrg-1)*h_plus))/chrg}\n"
            peak_ar = dta.peaks.unpack('e*')
            (0...(peak_ar.size)).step(2) do |i|
              out.print( peak_ar[i,2].join(' '), "\n")
            end
            out.print "END IONS\n"
            out.print "\n"
          end
        end
      end
    end
  end
end
