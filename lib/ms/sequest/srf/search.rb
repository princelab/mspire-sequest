
require 'tap/task'
require 'ms/sequest/srf'
require 'ms/mass'


# These are for outputting formats used in MS/MS Search engines

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

      # not given an out_folder, will make one with the basename
      # compress may be: :zip, :tgz, or nil (no compression)
      # :zip requires gem rubyzip to be installed and is *very* bloated
      # as it writes out all the files first!
      # :tgz requires gem archive-tar-minitar to be installed
      def to_dta_files(out_folder=nil, compress=nil)
        outdir = 
          if out_folder ; out_folder
          else base_name
          end

        case compress
        when :tgz
          begin
            require 'archive/tar/minitar'
          rescue LoadError
            abort "need gem 'archive-tar-minitar' installed' for tgz compression!\n#{$!}"
          end
          require 'archive/targz'  # my own simplified interface!
          require 'zlib'
          names = index.map do |i_ar|
            [outdir, '/', [base_name, *i_ar].join('.'), '.dta'].join('')
          end
          #Archive::Targz.archive_as_files(outdir + '.tgz', names, dta_file_data)

          tgz = Zlib::GzipWriter.new(File.open(outdir + '.tgz', 'wb'))

          Archive::Tar::Minitar::Output.open(tgz) do |outp|
            dta_files.each_with_index do |dta_file, i|
              Archive::Tar::Minitar.pack_as_file(names[i], dta_file.to_dta_file_data, outp)
            end
          end
        when :zip
          begin
            require 'zip/zipfilesystem'
          rescue LoadError
            abort "need gem 'rubyzip' installed' for zip compression!\n#{$!}"
          end
          #begin ; require 'zip/zipfilesystem' ; rescue LoadError, "need gem 'rubyzip' installed' for zip compression!\n#{$!}" ; end
          Zip::ZipFile.open(outdir + ".zip", Zip::ZipFile::CREATE) do |zfs|
            dta_files.zip(index) do |dta,i_ar|
              #zfs.mkdir(outdir)
              zfs.get_output_stream(outdir + '/' + [base_name, *i_ar].join('.') + '.dta') do |out|
                dta.write_dta_file(out)
                #zfs.commit
              end
            end
          end
        else  # no compression
          FileUtils.mkpath(outdir)
          Dir.chdir(outdir) do
            dta_files.zip(index) do |dta,i_ar|
              File.open([base_name, *i_ar].join('.') << '.dta', 'wb') do |out|
                dta.write_dta_file(out)
              end
            end
          end
        end
      end

      # Ms::Sequest::Srf::SrfToSearch::task converts to MS formats for DB
      # searching
      #
      # outputs the appropriate file or directory structure for <file>.srf:
      #     <file>.mgf    # file for mgf
      #     <file>        # the basename directory for dta
      class SrfToSearch < Tap::Task
        config :format, "mgf", :short => 'f' # mgf|dta (default: mgf)
        def process(srf_file)
          base = srf_file.sub(/\.srf$/i, '')
          newfile = 
            case format
            when 'dta'
              base
            when 'mgf'
              base << '.' << format
            end
          srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => false )
          # options just speed up reading since we don't need .out info anyway
          case format
          when 'mgf'
            srf.to_mgf(newfile)
          when 'dta'
            srf.to_dta_files(newfile)
          end
        end
      end


    end # Srf
  end # Sequest
end # Ms


