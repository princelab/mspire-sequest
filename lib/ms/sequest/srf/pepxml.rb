require 'ms/ident/pepxml'
require 'ms/ident/pepxml/spectrum_query'
require 'ms/ident/pepxml/search_result'
require 'ms/ident/pepxml/search_hit'
require 'ms/msrun'
require 'ms/sequest/srf'
require 'ms/sequest/pepxml'

class Ms::Sequest::Srf
  module Pepxml

    #  A hash with the following *symbol* keys may be set:
    #
    # Run Info
    # *:ms_model*:: nil
    # *:ms_ionization*:: 'ESI'
    # *:ms_detector*:: 'UNKNOWN'
    # *:ms_mass_analyzer*:: nil - <i>typically extracted from the srf file and matched with <b>ModelToMsAnalyzer</b></i>
    # *:ms_manufacturer*:: 'Thermo'
    #
    # Raw data
    # *:mz_dir*:: nil - <i>path to the mz[X]ML directory, defaults to the directory the srf file is contained in.  mz[X]ML data must be available to embed retention times</i>
    # *:raw_data*:: \['.mzML', '.mzXML'\] - <i>preferred extension for raw data</i>
    #
    # Database
    # *:db_seq_type*:: 'AA' - <i>AA or NA</i>
    # *:db_dir*:: nil - <i>the directory the fasta file used for the search is housed in. A valid pepxml file must point to a valid fasta file!</i>
    # *:db_residue_size*:: nil - <i>An integer for the number of residues in the database.  if true, calculates the size of the fasta database.</i>
    # *:db_name:: nil
    # *:db_orig_database_url*:: nil
    # *:db_release_date*:: nil
    # *:db_release_identifier*:: nil
    #
    # Search Hits
    # *:num_hits*:: 1 - <i>the top number of hits to include</i>
    # *:retention_times*:: false - <i>include retention times in the file (requires mz_dir to be set)</i>
    # *:deltacn_orig*:: false - <i>when true, the original SEQUEST deltacn values are used.  If false, Bioworks deltacn values are used which are derived by taking the original deltacn of the following hit.  This gives the top ranking hit an informative deltacn but makes the deltacn meaningless for other hits.</i>
    #
    # *:pepxml_version*:: Ms::Ident::Pepxml::DEFAULT_PEPXML_VERSION, - <i>Integer to set the pepxml version.  The converter and xml output attempts to produce xml specific to the version.</i>
    # *:verbose*:: true - <i>set to false to quiet warnings</i>
    DEFAULT_OPTIONS = {
      :ms_model => nil,
      :ms_ionization => 'ESI',
      :ms_detector => 'UNKNOWN',
      :ms_mass_analyzer => nil,
      :ms_manufacturer => 'Thermo',

      :mz_dir => nil,
      #:raw_data => [".mzXML", '.mzML'],
      :raw_data => ['.mzML', '.mzXML'],

      :db_seq_type => 'AA', 
      :db_dir => nil, 
      :db_residue_size => nil,
      :db_name => nil,
      :db_orig_database_url => nil,
      :db_release_date => nil,
      :db_release_identifier => nil,

      :num_hits => 1,
      :retention_times => false,
      :deltacn_orig => false,

      :pepxml_version => Ms::Ident::Pepxml::DEFAULT_PEPXML_VERSION,
      :verbose => true,
    }

    # An array of regexp to string pairs.  The regexps are matched against the
    # model (srf.header.model) and the corresponding string will be used as
    # the mass analyzer.
    #
    # /Orbitrap/:: 'Orbitrap'
    # /LCQ Deca XP/:: 'Ion Trap'
    # /LTQ/:: 'Ion Trap'
    # /\w+/:: 'UNKNOWN'
    ModelToMsAnalyzer = [
      [/Orbitrap/, 'Orbitrap'], 
      [/LCQ Deca XP/, 'Ion Trap'],
      [/LTQ/, 'Ion Trap'],
      [/\w+/, 'UNKNOWN'],
    ]

    # returns an Ms::Ident::Pepxml object.  See that object for creating an
    # xml string or writing to file.
    def to_pepxml(opts={})
      opt = DEFAULT_OPTIONS.merge(opts)
      srf = self

      # with newer pepxml version these are not required anymore
      hidden_opts = {
        # format of file storing the runner up peptides (if not present in
        # pepXML) this was made optional after version 19
        :out_data_type => "out", ## may be srf??
        # runner up search hit data type extension (e.g. .tgz)
        :out_data => ".srf",
      }
      opt.merge!(hidden_opts)

      params = srf.params
      header = srf.header

      opt[:ms_model] ||= srf.header.model

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
      if File.exist?(db_filename)
        db_filename = File.expand_path(db_filename)
      else
        msg = ["!!! WARNING !!!"]
        msg << "!!! Can't find database: #{db_filename}"
        msg << "!!! pepxml *requires* that the db path be valid"
        msg << "!!! make sure 1) the fasta file is available on this system"
        msg << "!!!           2) you've specified a valid directory with --db-dir (or :db_dir)"
        puts msg.join("\n") if opt[:verbose]
      end

      modifications_obj = Ms::Sequest::Pepxml::Modifications.new(params, srf.header.modifications)
      mass_index = params.mass_index(:precursor)
      h_plus = mass_index['h+']

      opt[:mz_dir] ||= srf.resident_dir
      found_ext = opt[:raw_data].find do |raw_data|
        Dir[File.join(opt[:mz_dir], srf.base_name_noext + raw_data)].first
      end
      opt[:raw_data] = [found_ext] if found_ext

      scan_to_ret_time = 
        if opt[:retention_times]
          mz_file = Dir[File.join(opt[:mz_dir], srf.base_name_noext + opt[:raw_data].first)].first
          if mz_file
            Ms::Msrun.scans_to_times(mz_file) 
          else
            warn "turning retention_times off since no valid mz[X]ML file was found!!!"
            opt[:retention_times] = false
            nil
          end
        end

      summary_xml_filename = srf.base_name_noext + '.xml'

      pepxml = Ms::Ident::Pepxml.new do |msms_pipeline_analysis|
        msms_pipeline_analysis.merge!(:summary_xml => summary_xml_filename, :pepxml_version => opt[:pepxml_version]) do |msms_run_summary|
          # prep the sample enzyme and search_summary
          msms_run_summary.merge!(
            :base_name => File.join(opt[:mz_dir], srf.base_name_noext),
            :ms_manufacturer => opt[:ms_manufacturer],
            :ms_model => opt[:ms_model],
            :ms_ionization => opt[:ms_ionization],
            :ms_mass_analyzer => opt[:ms_mass_analyzer],
            :ms_detector => opt[:ms_detector],
            :raw_data => opt[:raw_data].first,
            :raw_data_type => opt[:raw_data].first,
          ) do |sample_enzyme, search_summary, spectrum_queries|
            sample_enzyme.merge!(params.sample_enzyme_hash)
            search_summary.merge!(
              :base_name=> srf.resident_dir + '/' + srf.base_name_noext,
              :search_engine => 'SEQUEST',
              :precursor_mass_type => params.precursor_mass_type,
              :fragment_mass_type => params.fragment_mass_type,
              :out_data_type => opt[:out_data_type],
              :out_data => opt[:out_data],
            ) do |search_database, enzymatic_search_constraint, modifications_ar, parameters_hash|
              search_database.merge!(:local_path => db_filename, :seq_type => opt[:db_seq_type], :database_name => opt[:db_name], :orig_database_url => opt[:db_orig_database_url], :database_release_date => opt[:db_release_date], :database_release_identifier => opt[:db_release_identifier])

              case opt[:db_residue_size]
              when Integer
                search_database.size_of_residues = opt[:db_residue_size]
              when true
                search_database.set_size_of_residues!
              end

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
                (prev_aa, pure_aaseq, next_aa) = Ms::Ident::Peptide.prepare_sequence(pep.sequence)
                calc_neutral_pep_mass = pep.mh - h_plus
                sh = Ms::Ident::Pepxml::SearchHit.new(
                  :hit_rank => i+1, 
                  :peptide => pure_aaseq, 
                  :peptide_prev_aa => prev_aa,
                  :peptide_next_aa => next_aa,
                  :protein => pep.proteins.first.reference.split(' ')[0],
                  :num_tot_proteins => pep.proteins.size,
                  :num_matched_ions => pep.ions_matched,
                  :tot_num_ions => pep.ions_total,
                  :calc_neutral_pep_mass => calc_neutral_pep_mass, 
                  :massdiff => precursor_neutral_mass - calc_neutral_pep_mass,
                  :num_tol_term => sample_enzyme.num_tol_term(prev_aa, pure_aaseq, next_aa),
                  :num_missed_cleavages => sample_enzyme.num_missed_cleavages(pure_aaseq),
                  :modification_info => modifications_obj.modification_info(Ms::Ident::Peptide.split_sequence(pep.sequence)[1])
                ) do |search_scores|
                  if opt[:deltacn_orig]
                    deltacn = pep.deltacn_orig
                    deltacnstar = nil
                  else
                    deltacn = pep.deltacn
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
            spectrum_queries.replace(spec_queries)
          end
        end
      end
      pepxml
    end # to_pepxml
  end # Srf::Pepxml
  include Pepxml
end # Srf


require 'trollop'

module Ms::Sequest::Srf::Pepxml
  def self.commandline(argv, progname=$0)
    opts = Trollop::Parser.new do
      banner %Q{
        usage: #{progname} [OPTIONS] <file>.srf ...
        output: <file>.xml ...
      }.lines.map(&:lstrip).join

      text ""
      text "major options:"
      opt :db_dir, "The dir holding the DB if different than in Srf. (pepxml requires a valid database path)", :type => :string
      opt :mz_dir, "directory holding mz[X]ML files (defaults to the folder holding the srf file)", :type => :string
      opt :retention_times, "include retention times (requires mz-dir)"
      opt :deltacn_orig, "use original deltacn values created by SEQUEST.  By default, the top hit gets the next hit's original deltacn."
      opt :no_filter, "do not filter hits by peptide_mass_tolerance (per sequest params)"
      opt :num_hits, "include N top hits", :default => 1
      opt :outdirs, "list of output directories", :type => :strings
      opt :quiet, "do not print warnings, etc."

      text ""
      text "minor options:"
      opt :ms_model, 'mass spectrometer model', :type => :string
      opt :ms_ionization, 'type of ms ionization', :default => 'ESI'
      opt :ms_detector, 'ms detector', :default => 'UNKNOWN'
      opt :ms_mass_analyzer, 'ms mass analyzer', :type => :string
      opt :ms_manufacturer, 'ms manufacturer', :default => 'Thermo'
      opt :raw_data, 'preferred extension for raw data', :default => '.mzXML'
      opt :db_seq_type, "'AA' or 'NA'", :default => 'AA'
      opt :db_residue_size, 'calculate the size of the fasta file'
      opt :db_name, 'the database name', :type => :string
      opt :db_orig_database_url, 'original database url', :type => :string
      opt :db_release_date, 'database release date', :type => :string
      opt :db_release_identifier, 'the database release identifier', :type => :string
    end

    opt = opts.parse argv
    opts.educate && exit if argv.empty?

    Trollop.die :outdirs, "outdirs must be same size as number of input files" if opt.outdirs && opt.outdirs.size != argv.size
    opt[:filter] = !opt.delete(:no_filter)
    opt[:outdirs] ||= []
    opt[:raw_data] = [opt[:raw_data]] if opt[:raw_data]
    opt[:verbose] = !opt[:quiet]

    argv.zip(opt.delete(:outdirs)) do |srf_file,outdir|
      outdir ||= File.dirname(srf_file)
      srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => opt.delete(:filter))
      pepxml = srf.to_pepxml(opt)
      outfile = pepxml.to_xml(outdir)
      puts "wrote file: #{outfile}" if opt[:verbose]
    end
  end
end




