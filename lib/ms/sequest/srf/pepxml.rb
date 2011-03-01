require 'ms/sequest/srf'
require 'ms/ident/pepxml'
require 'ms/sequest/pepxml'
require 'ms/msrun'

class Ms::Sequest::Srf
  module Pepxml

    DEFAULT_OPTIONS = {
      ## MSMSRunSummary options:
      # string must be recognized in sample_enzyme.rb 
      # or create your own SampleEnzyme object
      :ms_ionization => 'ESI',
      :ms_detector => 'UNKNOWN',
      :raw_data => [".mzXML", '.mzML'],  # preference  
      :db_seq_type => 'AA', # AA or NA
      :ms_mass_analyzer => nil,
      :outbasename => nil,
      :retention_times => false,
      :num_hits => 1, # the top number of hits to include
      :mzxml_dir => nil, # path to the mzxml directory
      :ms_manufacturer => 'Thermo',
      # requires mzxml_dir to be set
      :retention_times => false,
      :pepxml_version => Ms::Ident::Pepxml::DEFAULT_PEPXML_VERSION,
      ## SearchSummary options:
    }

    # can set :ms_mass_analyzer directly, or use a regexp to provide the
    # ms_mass_analyzer value.
    ModelToMsAnalyzer = [
      [/Orbitrap/, 'Orbitrap'], 
      [/LCQ Deca XP/, 'Ion Trap'],
      [/LTQ/, 'Ion Trap'],
      [/\w+/, 'UNKNOWN'],
    ]

    # Generates pepxml xml.  If outdir is nil, the outdir will be derived from
    # the raw filename.
    #
    # returns the full path of the output file.
    #
    # the filename will be based on the raw filename, unless :outbasename is
    # specified.
    # if outdir is :object, then the pepxml object itself is returned (and
    # nothing is written to file)
    def to_pepxml(outdir=nil, opts={})
      opt = DEFAULT_OPTIONS.merge(opts)
      srf = self

      # with newer pepxml version these are not required anymore
      hidden_opts = {
        :raw_data_type => "raw",
        :out_data_type => "out", ## may be srf??
        :out_data => ".tgz", ## may be srf??
        # :ms_mass_analyzer => 'Orbitrap', ???? 
      }
      opt.merge!(hidden_opts)
      opt[:outdir] = 
        if outdir 
          if outdir==:object
            object_output = true
            '.'
          else
            outdir
          end
        else
          srf.header.raw_filename.split(/[\/\\]+/)[0..-2].join('/')
        end

      params = srf.params
      header = srf.header

      #bn_noext = if out_filename
      #  
      #             base_name_noext(srf.header.raw_filename)

      opt[:ms_model] = srf.header.model

      unless opt[:ms_mass_analyzer]
        ModelToMsAnalyzer.each do |regexp, val|
          if opt[:ms_model].match(regexp)
            opt[:ms_mass_analyzer] = val
            break
          end
        end
      end

      # get the database name
      db_filename = header.db_filename.sub(/\.hdr$/, '')
      if opt[:db_dir]
        db_filename = File.join(opt[:db_dir], db_filename.split(/[\/\\]+/).last)
      end
      unless File.exist?(db_filename)
        $stderr.puts "!!! Can't find database: #{db_filename}"
        $stderr.puts "!!! pepxml *requires* that the db path be valid"
        $stderr.puts "!!! make sure 1) the fasta file is available on this system"
        $stderr.puts "!!!           2) you've specified a valid directory with --db-dir (or :db_dir)"
      end
      db_filename = File.expand_path(db_filename)

      modifications_obj = Ms::Sequest::Pepxml::Modifications.new(params, srf.header.modifications)
      mass_index = params.mass_index(:precursor)
      h_plus = mass_index['h+']

      scan_to_ret_time = 
        if opt[:retention_times]
          mz_file = opt[:raw_data].map do |raw_data|
            Dir[File.join(opt[:mz_dir], srf.base_name_noext + raw_data)].first
          end.compact.first
          if mz_file
            Ms::Msrun.scans_to_times(mz_file) 
          else
            warn "turning retention_times off since no valid mz[X]ML file was found!!!"
            opt[:retention_times] = false
            Hash.new
          end
        end

      summary_xml_filename = File.join(outdir, srf.base_name_noext + '.xml')

      pepxml = Pepxml.new do |msms_pipeline_analysis|
        msms_pipeline_analysis.merge!(:summary_xml => summary_xml_filename, :pepxml_version => opt[:pepxml_version]) do |msms_run_summary|
          # prep the sample enzyme and search_summary
          msms_run_summary.merge!(
            :base_name => opt[:mzxml_dir],
            :ms_manufacturer => opt[:ms_manufacturer],
            :ms_model => opt[:ms_model],
            :ms_ionization => opt[:ms_ionization],
            :ms_mass_analyzer => opt[:ms_mass_analyzer],
            :ms_detector => opt[:ms_detector],
            :raw_data => opt[:raw_data].first
          ) do |sample_enzyme, search_summary, spectrum_queries|
            sample_enzyme.merge!(params.sample_enzyme_hash)
            search_summary.merge!(
              :base_name=> srf.resident_dir + '/' + srf.base_name_noext,
              :search_engine => 'SEQUEST',
              :precursor_mass_type => params.precursor_mass_type,
              :fragment_mass_type => params.fragment_mass_type,
            ) do |search_database, enzymatic_search_constraint, modifications_ar, parameters_hash|
              search_database.merge!(:local_path => db_filename, :seq_type => opt[:db_seq_type]) # note seq_type == type
              enzymatic_search_constraint.merge!(
                :enzyme => params.enzyme, 
                :max_num_internal_cleavages => params.max_num_internal_cleavages,
                :min_number_termini => params.min_number_termini,
              )
              modifications_ar.replace(modifications_obj.modifications)
              parameters_hash.merge!(params.opts)
            end

            spec_queries = srf.dta_files.zip(srf.out_files, index).map do |dta_file,out_file,i_ar|
              precursor_neutral_mass = dta_file.mh - h_plus

              search_hits = out_file.hits[0,opt[:num_hits]].each_with_index.map do |pep,i|
                (prev_aa, pure_aaseq, next_aa) = Ms::Id::Peptide.prepare_sequence(pep.sequence)
                calc_neutral_pep_mass = pep.mh - h_plus
                sh = Ms::Ident::Pepxml::SearchHit.new(
                  :hit_rank => i+1, 
                  :peptide => pure_aaseq, 
                  :peptide_prev_aa => prev_aa,
                  :peptide_next_aa => next_aa,
                  :protein => prots.first.reference.split(' ')[0],
                  :num_tot_proteins => prots.size,
                  :num_matched_ions => pep.ions_matched,
                  :tot_num_ions => pep.ions_total,
                  :calc_neutral_pep_mass => calc_neutral_pep_mass, 
                  :massdiff => precursor_neutral_mass - calc_neutral_pep_mass,
                  :num_tol_term => sample_enzyme.num_tol_term(prev_aa, pure_aaseq, next_aa),
                  :num_missed_cleavages => sample_enzyme.num_missed_cleavages(pure_aaseq),
                  :modification_info => modifications_obj.modification_info
                ) do |search_scores|
                  if opt[:deltacn_orig]
                    deltacn = pep.deltacn_orig
                    deltacnstar = nil
                  else
                    deltacn = pep.deltcn
                    deltacn = 1.0 if deltacn == 1.1
                    deltcnstar = out_file.hits[i+1].nil? ? '1' : '0'
                  end
                  search_scores.merge!( :xcorr => pep.xcorr, :deltcn => deltacn, 
                                       :spscore => pep.sp, :sprank => pep.rsp)
                  search_scores[:deltacnstar] = deltacnstar if deltacnstar
                end
              end

              sr = Ms::Ident::Pepxml::SearchResult.new(:search_hits => search_hits)

              ret_time = 
                if opt[:retention_times]
                  (first_scan, last_scan) = i_ar[0,2]
                  if first_scan==last_scan
                    scan_to_ret_time[i_ar[0]]
                  else
                    times = ((i_ar[0])..(i_ar[1])).step(1).map {|i| scan_to_ret_time[i] }.compact
                    times.inject(&:+) / times.size.to_f
                  end
                end
              Ms::Ident::Pepxml::SpectrumQuery.new(
                :spectrum  => [srf.base_name_noext, *i_ar].join('.'), :start_scan => i_ar[0], :end_scan => i_ar[1], 
                :precursor_neutral_mass => dta_file.mh - h_plus, :assumed_charge => i_ar[2],
                :retention_time_sec => ret_time,  
                :search_results => [sr], 
              )
            end
          end
        end
      end
      if object_output
        pepxml
      else
        pepxml.to_xml(summary_xml_filename)
        summary_xml_filename
      end
    end # to_pepxml
  end # Srf::Pepxml
  include Pepxml
end # Srf


require 'optparse'

module Ms::Sequest::Srf::Pepxml
 def self.commandline(argv, progname=$0)
    opt = {
      :filter => true,
      :num_hits => 1,
      :retention_times => false,
    }
    opts = OptionParser.new do |op|
      op.banner = "usage: #{progname} [OPTIONS] <file>.srf ..."
      op.separator "output: <file>.xml ..."
      op.separator ""
      op.separator "options:"
      op.on("--mz-dir <String>", "directory holding mz[X]ML files") {|v| opt[:mz_dir] = v }
      op.on("--retention-times", "include retention times (requires mz-dir)") {|v| opt[:retention_times] = true }
      op.on("-d", "--db-info", "calculates extra database information") {|v| opt[:db_info] = v }
      op.on("-p", "--db-dir <String>", "The dir holding the DB if different than in Srf", "[pepxml requires a valid database path]") {|v| opt[:db_dir] = v }
      op.on("--deltacn-orig", "use original deltacn values reported", "by default, the top hit gets the next hit's original deltacn.") {|v| opt[:deltacn_orig] = v }
      op.on("-n", "--no-filter", "by default, pephit must be within peptide_mass_tolerance",  "(defined in sequest.params) to be included.  Turns this off.") { opt[:filter] = false }
      op.on("-h", "--num-hits <Int>", Integer, "include N top hits (default:#{opt[:num_hits]})") {|v| opt[:num_hits] = v }
      op.on("-o", "--outdirs <first,...>", Array, "Comma list of output directories") {|v| opt[:outfiles] = v }
    end
    opts.parse!(argv)

    if argv.size == 0
      puts(opts) || exit
    end

    if opt[:outdirs] && (opt[:outdirs].size != argv.size)
      raise "if outdirs specified, outdirs must be same size as number of input files"
    end

    argv.each_with_index do |srf_file,i|
      outdir = 
        if opt[:outdirs]
          opt[:outdirs][i]
        else
          File.dirname(srf_file)
        end

      srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => opt.delete(:filter))
      srf.to_pepxml(outdir, opt)
    end
  end
end




