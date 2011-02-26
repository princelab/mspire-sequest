require 'ms/sequest/srf'
require 'ms/ident/pepxml'
require 'ms/ident/parameters'

class Ms::Sequest::Srf
  module Pepxml

    DEFAULT_OPTIONS = {
      ## MSMSRunSummary options:
      # string must be recognized in sample_enzyme.rb 
      # or create your own SampleEnzyme object
      :ms_manufacturer => 'Thermo',
      :ms_model => 'LTQ Orbitrap',
      :ms_ionization => 'ESI',
      :ms_mass_analyzer => 'Orbitrap',
      :ms_detector => 'UNKNOWN',
      :raw_data_type => "raw",
      :raw_data => ".mzXML", ## even if you don't have it?
      ## SearchSummary options:
      :out_data_type => "out", ## may be srf??
      :out_data => ".tgz", ## may be srf??
    }

    def to_pepxml(out_filename=nil, opts={})
      opts = DEFAULT_OPTIONS.merge(opts)

      ## set the outpath
      out_path = opts.delete(:out_path)

      params = srf.params

      ## check to see if we need backup_db
      backup_db_path = opts.delete(:backup_db_path)
      if !File.exist?(params.database) && backup_db_path
        params.database_path = backup_db_path
      end

      #######################################################################
      # PREPARE THE OPTIONS:
      #######################################################################
      ## remove items from the options hash that don't belong to 
      ppxml_version = opts.delete(:pepxml_version)
      out_data_type = opts.delete(:out_data_type)
      out_data = opts.delete(:out_data)

      ## Extract meta info from srf
      bn_noext = base_name_noext(srf.header.raw_filename)
      opts[:ms_model] = srf.header.model
      case opts[:ms_model]
      when /Orbitrap/
        opts[:ms_mass_analyzer] = 'Orbitrap'
      when /LCQ Deca XP/
        opts[:ms_mass_analyzer] = 'Ion Trap'
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
      op.on("-p", "--db-path <String>", "If you need to specify the database path") {|v| opt[:new_db_path] = v }
      op.on("-u", "--db-update", "update the sqt file to reflect --db_path") {|v| opt[:db_update] = v }
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
      srf.to_pepxml(outfile, :db_info => opt[:db_info], :new_db_path => opt[:new_db_path], :update_db_path => opt[:db_update], :round => opt[:round])
    end
  end
end




