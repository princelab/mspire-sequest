
require 'mspire/sequest/srf'
require 'mspire/mass'

# These are for outputting formats used in MS/MS Search engines

module Mspire
  module Sequest
    class Srf
      module Search
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
          h_plus = Mspire::Mass::H_PLUS
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
        def to_dta(out_folder=nil, compress=nil)
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
      end # Search

      include Search

    end # Srf
  end # Sequest
end # MS


require 'optparse'
module Mspire::Sequest::Srf::Search
  def self.commandline(argv, progname=$0)
    opt = {
      :format => 'mgf'
    }
    opts = OptionParser.new do |op|
      op.banner = "usage: #{File.basename(__FILE__)} <file>.srf ..."
      op.separator "outputs: <file>.mgf ..."
      op.on("-f", "--format <mgf|dta>", "the output format (default: #{opt[:format]})") {|v| opt[:format] = v }
      op.on("-o", "--outfiles <String,...>", Array, "comma list of output files or directories") {|v| opt[:outfiles] = v }
    end

    opts.parse!(argv)

    if argv.size == 0
      puts(opts) || exit
    end

    format = opt[:format]

    if opt[:outfiles] && (opt[:outfiles].size != argv.size)
      raise "if outfiles specified, needs the same number of files as input files"
    end

    argv.each_with_index do |srf_file,i|
      base = srf_file.chomp(File.extname(srf_file))
      newfile = 
        if opt[:outfiles]
          opt[:outfiles][i]
        else
          case format
          when 'dta'
            base
          when 'mgf'
            base << '.' << format
          end
        end
      srf = Mspire::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => false, :read_pephits => false )
      # options just speed up reading since we don't need .out info anyway
      case format
      when 'mgf'
        srf.to_mgf(newfile)
      when 'dta'
        srf.to_dta(newfile)
      end
    end
  end
end
