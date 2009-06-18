
module Ms
  module Sequest
    class Srf

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

    end # Srf
  end # Sequest
end # Ms


