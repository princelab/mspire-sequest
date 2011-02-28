require 'ms/sequest/srf'
require 'ms/ident/pepxml'
require 'ms/sequest/pepxml'

class Ms::Sequest::Srf
  module Pepxml

    DEFAULT_OPTIONS = {
      ## MSMSRunSummary options:
      # string must be recognized in sample_enzyme.rb 
      # or create your own SampleEnzyme object
      :ms_ionization => 'ESI',
      :ms_detector => 'UNKNOWN',
      :raw_data => ".mzXML", ## even if you don't have it?
      :db_seq_type => 'AA', # AA or NA
      :ms_mass_analyzer => nil,
      :outbasename => nil,
      :mzxml_dir => nil, # path to the mzxml directory
      :ms_manufacturer => 'Thermo',
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
    # 
    def to_pepxml(outdir=nil, opts={})
      srf = self
      opts = DEFAULT_OPTIONS.merge(opts)

      # with newer pepxml version these are not required anymore
      hidden_opts = {
        :raw_data_type => "raw",
        :out_data_type => "out", ## may be srf??
        :out_data => ".tgz", ## may be srf??
        # :ms_mass_analyzer => 'Orbitrap', ???? 
      }
      opts.merge!(hidden_opts)
      opts[:outdir] = 
        if outdir ; outdir
        else
          srf.header.raw_filename.split(/[\/\\]+/)[0..-2].join('/')
        end

      params = srf.params
      header = srf.header

      #bn_noext = if out_filename
      #  
      #             base_name_noext(srf.header.raw_filename)

      opts[:ms_model] = srf.header.model

      unless opts[:ms_mass_analyzer]
        ModelToMsAnalyzer.each do |regexp, val|
          if opts[:ms_model].match(regexp)
            opts[:ms_mass_analyzer] = val
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

      pepxml = Pepxml.new do |msms_pipeline_analysis|
        msms_pipeline_analysis.merge!(:summary_xml => srf.base_name_noext + '.xml', :pepxml_version => opts[:pepxml_version]) do |msms_run_summary|
          # prep the sample enzyme and search_summary
          msms_run_summary.merge!(
            :base_name => opts[:mzxml_dir],
            :ms_manufacturer => opts[:ms_manufacturer],
            :ms_model => opts[:ms_model],
            :ms_ionization => opts[:ms_ionization],
            :ms_mass_analyzer => opts[:ms_mass_analyzer],
            :ms_detector => opts[:ms_detector],
          ) do |sample_enzyme, search_summary, spectrum_queries|
            sample_enzyme.merge!(params.sample_enzyme_hash)
            search_summary.merge!(
              :base_name=> srf.resident_dir + '/' + srf.base_name_noext,
              :search_engine => 'SEQUEST',
              :precursor_mass_type => params.precursor_mass_type,
              :fragment_mass_type => params.fragment_mass_type,
            ) do |search_database, enzymatic_search_constraint, modifications, parameters|
              search_database.merge!(:local_path => db_filename, :seq_type => opts[:db_seq_type]) # note seq_type == type
              enzymatic_search_constraint.merge!(
                :enzyme => params.enzyme, 
                :max_num_internal_cleavages => params.max_num_internal_cleavages,
                :min_number_termini => params.min_number_termini,
              )
              modifications << Pepxml::AminoacidModification.new(
                :aminoacid => 'M', :massdiff => 15.9994, :mass => Ms::Mass::AA::MONO['M']+15.9994,
                :variable => 'Y', :symbol => '*')
                # invented, for example, a protein terminating mod
                modifications << Pepxml::TerminalModification.new( 
                                                                  :terminus => 'c', :massdiff => 23.3333, :mass => Ms::Mass::MONO['oh'] + 23.3333, 
                                                                  :variable => 'Y', :symbol => '[', :protein_terminus => 'c', 
                                                                  :description => 'leave protein_terminus off if not protein mod'
                                                                 )
                                                                 modifications << Pepxml::TerminalModification.new( 
                                                                                                                   :terminus => 'c', :massdiff => 25.42322, :mass => Ms::Mass::MONO['h+'] + 25.42322, 
                                                                                                                   :variable => 'N', :symbol => ']', :description => 'example: c term mod'
                                                                                                                  )
                                                                                                                  parameters.merge!( 
                                                                                                                                    :fragment_ion_tolerance => 1.0000, 
                                                                                                                                    :digest_mass_range => '600.0 3500.0', 
                                                                                                                                    :enzyme_info => 'Trypsin(KR/P) 1 1 KR P', # etc.... 
                                                                                                                                   )
            end
            spectrum_query1 = Pepxml::SpectrumQuery.new(
              :spectrum  => '020.3.3.1', :start_scan => 3, :end_scan => 3, 
              :precursor_neutral_mass => 1120.93743421875, :assumed_charge => 1
            ) do |search_results|
              search_result1 = Pepxml::SearchResult.new do |search_hits|
                modpositions = [[1, 243.1559], [6, 167.0581], [7,181.085]].map do |pair|  
                  Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new(*pair)
                end
                # order(modified_peptide, mod_aminoacid_masses, :mod_nterm_mass, :mod_cterm_mass)
                # or can be set by hash
                mod_info = Pepxml::SearchHit::ModificationInfo.new('Y#RLGGS#T#K', modpositions)
                search_hit1 = Pepxml::SearchHit.new( 
                                                    :hit_rank=>1, :peptide=>'YRLGGSTK', :peptide_prev_aa => "R", :peptide_next_aa => "K",
                                                    :protein => "gi|16130113|ref|NP_416680.1|", :num_tot_proteins => 1, :num_matched_ions => 5,
                                                    :tot_num_ions => 35, :calc_neutral_pep_mass => 1120.93163442, :massdiff => 0.00579979875010395,
                                                    :num_tol_term => 2, :num_missed_cleavages => 1, :is_rejected => 0, 
                                                    :modification_info => mod_info) do |search_scores|
                  search_scores.merge!(:xcorr => 0.12346, :deltacn => 0.7959, :deltacnstar => 0, 
                                       :spscore => 29.85, :sprank => 1)
                                                    end
                search_hits << search_hit1
              end
              search_results << search_result1
            end
            spectrum_queries << spectrum_query1
          end
        end
      end






      ## Create the base name
      full_base_name_no_ext = make_base_name( File.expand_path(out_path), bn_noext)
      opts[:base_name] = full_base_name_no_ext

      ## Create the search summary:
      search_summary_options = {
        :search_database => Ms::Ident::Pepxml::SearchDatabase.new(params),
        :base_name => full_base_name_no_ext,
        :out_data_type => out_data_type,
        :out_data => out_data
      }
      modifications_string = srf.header.modifications
      search_summary = Ms::Ident::Pepxml::SearchSummary.new( params, modifications_string, search_summary_options)

      # create the sample enzyme from the params object:
      sample_enzyme_obj = 
        if opts[:sample_enzyme]
          opts[:sample_enzyme]
        else
          params.sample_enzyme
        end
      opts[:sample_enzyme] = sample_enzyme_obj

      ## Create the pepxml obj and top level objects
      pepxml_obj = Ms::Ident::Pepxml.new(ppxml_version, params) 
      pipeline = Ms::Ident::Pepxml::MSMSPipelineAnalysis.new({:date=>nil,:summary_xml=> bn_noext +'.xml'})
      pepxml_obj.msms_pipeline_analysis = pipeline
      pipeline.msms_run_summary = Ms::Ident::Pepxml::MSMSRunSummary.new(opts)
      pipeline.msms_run_summary.search_summary = search_summary
      modifications_obj = search_summary.modifications

      ## name some common variables we'll need
      h_plus = pepxml_obj.h_plus
      avg_parent = pepxml_obj.avg_parent

      #######################################################################
      # CREATE the spectrum_queries_ar
      #######################################################################
      srf_index = srf.index
      out_files = srf.out_files
      spectrum_queries_arr = Array.new(srf.dta_files.size)
      files_with_hits_index = 0  ## will end up being 1 indexed

      deltacn_orig = opts[:deltacn_orig]
      deltacn_index = 
        if deltacn_orig ; 20
        else 19
        end

      srf.dta_files.each_with_index do |dta_file,dta_i|
        next if out_files[dta_i].num_hits == 0
        files_with_hits_index += 1

        precursor_neutral_mass = dta_file.mh - h_plus

        (start_scan, end_scan, charge) = srf_index[dta_i]
        sq_hash = {
          :spectrum => [bn_noext, start_scan, end_scan, charge].join('.'),
          :start_scan => start_scan,
          :end_scan => end_scan,
          :precursor_neutral_mass => precursor_neutral_mass,
          :assumed_charge => charge.to_i,
          :pepxml_version => ppxml_version,
          :index => files_with_hits_index,
        }

        spectrum_query = Ms::Ident::Pepxml::SpectrumQuery.new(sq_hash)


        hits = out_files[dta_i].hits

        search_hits = 
          if opts[:all_hits]
            Array.new(out_files[dta_i].num_hits)  # all hits
          else
            Array.new(1)  # top hit only
          end

        (0...(search_hits.size)).each do |hit_i|
          hit = hits[hit_i]
          # under the modified deltacn schema (like bioworks)
          # Get proper deltacn and deltacnstar
          # under new srf, deltacn is already corrected for what prophet wants,
          # deltacn_orig_updated is how to access the old one
          # Prophet deltacn is not the same as the native Sequest deltacn
          # It is the deltacn of the second best hit!

          ## mass calculations:
          calc_neutral_pep_mass = hit[0] - h_plus


          sequence = hit.sequence

          #  NEED TO MODIFY SPLIT SEQUENCE TO DO MODS!
          ## THIS IS ALL INNER LOOP, so we make every effort at speed here:
          (prevaa, pepseq, nextaa) = SpecID::Pep.prepare_sequence(sequence)
          # 0=mh 1=deltacn_orig 2=sp 3=xcorr 4=id 5=num_other_loci 6=rsp 7=ions_matched 8=ions_total 9=sequence 10=prots 11=deltamass 12=ppm 13=aaseq 14=base_name 15=first_scan 16=last_scan 17=charge 18=srf 19=deltacn 20=deltacn_orig_updated

          sh_hash = {
            :hit_rank => hit_i+1,
            :peptide => pepseq,
            :peptide_prev_aa => prevaa,
            :peptide_next_aa => nextaa,
            :protein => hit[10].first.reference.split(" ").first, 
            :num_tot_proteins => hit[10].size,
            :num_matched_ions => hit[7],
            :tot_num_ions => hit[8],
            :calc_neutral_pep_mass => calc_neutral_pep_mass,
            :massdiff => precursor_neutral_mass - calc_neutral_pep_mass, 
            :num_tol_term => sample_enzyme_obj.num_tol_term(sequence),
            :num_missed_cleavages => sample_enzyme_obj.num_missed_cleavages(pepseq),
            :is_rejected => 0,
            # These are search score attributes:
            :xcorr => hit[3],
            :deltacn => hit[deltacn_index],
            :spscore => hit[2],
            :sprank => hit[6],
            :modification_info => modifications_obj.modification_info(SpecID::Pep.split_sequence(sequence)[1]),
          }
          unless deltacn_orig
            sh_hash[:deltacnstar] = 
              if hits[hit_i+1].nil?  # no next hit? then its deltacnstar == 1
                '1'
              else
                '0'
              end
          end
          search_hits[hit_i] = Ms::Ident::Pepxml::SearchHit.new(sh_hash) # there can be multiple hits
        end

        search_result = Ms::Ident::Pepxml::SearchResult.new
        search_result.search_hits = search_hits
        spectrum_query.search_results = [search_result]
        spectrum_queries_arr[files_with_hits_index] = spectrum_query
      end
      spectrum_queries_arr.compact!

      pipeline.msms_run_summary.spectrum_queries = spectrum_queries_arr 
      pepxml_obj.base_name = pipeline.msms_run_summary.base_name
      pipeline.msms_run_summary.spectrum_queries =  spectrum_queries_arr 

      pepxml_obj
    end

    def summary_xml
      base_name + ".xml"
    end

    def precursor_mass_type
      @params.precursor_mass_type
    end

    def fragment_mass_type
      @params.fragment_mass_type
    end

    # combines filename in a manner consistent with the path
    def self.make_base_name(path, filename)
      sep = '/'
      if path.split('/').size < path.split("\\").size
        sep = "\\"
      end
      if path.split('').last == sep
        path + File.basename(filename)
      else
        path + sep + File.basename(filename)
      end
    end

    # outputs pepxml, (to file if given)
    def to_pepxml(file=nil)
      string = header
      string << @msms_pipeline_analysis.to_pepxml

      if file
        File.open(file, "w") do |fh| fh.print string end
      end
      string
    end

    # given any kind of filename (from windows or whatever)
    # returns the base of the filename with no file extension
    def self.base_name_noext(file)
      file.gsub!("\\", '/')
      File.basename(file).sub(/\.[\w^\.]+$/, '')
    end
  end # Pepxml
  include Pepxml
end # Ms::Sequest::Srf

require 'optparse'

module Ms::Sequest::Srf::Pepxml
 def self.commandline(argv, progname=$0)
    opt = {
      :filter => true
    }
    opts = OptionParser.new do |op|
      op.banner = "usage: #{progname} [OPTIONS] <file>.srf ..."
      op.separator "output: <file>.xml ..."
      op.separator ""
      op.separator "options:"
      op.on("-d", "--db-info", "calculates extra database information") {|v| opt[:db_info] = v }
      op.on("-p", "--db-dir <String>", "The dir holding the DB if different than in Srf", "[pepxml requires a valid path]") {|v| opt[:db_dir] = v }
      op.on("-n", "--no-filter", "by default, pephit must be within peptide_mass_tolerance",  "(defined in sequest.params) to be included.  Turns this off.") { opt[:filter] = false }
      op.on("-o", "--outfiles <first,...>", Array, "Comma list of output filenames") {|v| opt[:outfiles] = v }
    end
    opts.parse!(argv)

    if argv.size == 0
      puts(opts) || exit
    end

    if opt[:outfiles] && (opt[:outfiles].size != argv.size)
      raise "if outfiles specified, outfiles must be same size as number of input files"
    end

    argv.each_with_index do |srf_file,i|
      outfile = 
        if opt[:outfiles]
          opt[:outfiles][i]
        else
          base = srf_file.chomp(File.extname(srf_file))
          base + '.xml'
        end

      srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => opt.delete(:filter))
      srf.to_pepxml(outfile, :db_info => opt[:db_info], :db_dir => opt[:db_dir], :round => opt[:round])
    end
  end
end




