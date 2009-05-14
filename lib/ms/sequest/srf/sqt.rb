
module Ms
  module Sequest
    class Srf

      # the out_filename will be the base_name + .sqt unless 'out_filename' is
      # defined
      # :round => round floating point numbers
      # etc...
      def to_sqt(out_filename=nil, opts={})
        # default rounding precision (Decimal Places)
        tic_dp = 2
        mh_dp = 7
        xcorr_dp = 5
        sp_dp = 2
        dcn_dp = 5

        defaults = {:db_info=>false, :new_db_path=>nil, :update_db_path=>false, :round=>false}
        opt = defaults.merge(opts)

        outfile =
          if out_filename
            out_filename
          else
            base_name + '.sqt'
          end
        invariant_ordering = %w(SQTGenerator SQTGeneratorVersion Database FragmentMasses PrecursorMasses StartTime) # just for readability and consistency
        fmt = 
          if params.fragment_mass_type == 'average' ; 'AVG'
          else ; 'MONO'
          end
        pmt =
          if params.precursor_mass_type == 'average' ; 'AVG'
          else ; 'MONO'
          end

        mass_table = params.mass_table
        static_mods = params.static_mods.map do |k,v|
          key =  k.split(/_/)[1]
          if key.size == 1
            key + '=' + (mass_table[key.to_sym] + v.to_f).to_s
          else
            key + '=' + v
          end
        end

        dynamic_mods = []
        header.modifications.scan(/\((.*?)\)/) do |match|
          dynamic_mods << match.first.sub(/ /,'=')
        end
        plural = {
          'StaticMod' => static_mods,
          'DynamicMod' => dynamic_mods,  # example as diff mod
          'Comment' => ['Created from Bioworks .srf file']
        }


        db_filename = header.db_filename
        db_filename_in_sqt = db_filename
        if opt[:new_db_path]
          db_filename = File.join(opt[:new_db_path], File.basename(db_filename.gsub('\\', '/')))
          if opt[:update_db_path]
            db_filename_in_sqt = File.expand_path(db_filename)
            warn "writing Database #{db_filename} to sqt, but it does not exist on this file system" unless File.exist?(db_filename) 
          end
        end

        apmu = 
          case params.peptide_mass_units 
          when '0' : 'amu' 
          when '1' : 'mmu'
          when '2' : 'ppm'
          end

        hh =  {
          'SQTGenerator' => "mspire (ms-sequest #{Ms::Sequest::VERSION})",
          'SQTGeneratorVersion' => Mspire::Version,
          'Database' => db_filename_in_sqt,
          'FragmentMasses' => fmt,
          'PrecursorMasses' => pmt,
          'StartTime' => '',  # Bioworks 3.2 also leaves this blank...
          'Alg-PreMassTol' => params.peptide_mass_tolerance,
          'Alg-FragMassTol' => params.fragment_ion_tolerance,
          'Alg-PreMassUnits' => apmu, ## mine
          'Alg-IonSeries' => header.ion_series.split(':').last.lstrip,
          'Alg-Enzyme' => header.enzyme.split(':').last,
          'Alg-MSModel' => header.model,
        }

        if opt[:db_info]
          if File.exist?(db_filename)
            reply = Ms::Sequest::Sqt.get_db_info_for_sqt(db_filename)
            %w(DBSeqLength DBLocusCount DBMD5Sum).zip(reply) do |label,val|
              hh[label] = val
            end
          else
            warn "file #{db_filename} does not exist, no extra db info in header!"
          end
        end

        has_hits = (self.out_files.size > 0)
        if has_hits
          # somewhat redundant with above, but we can get this without a db present!
          hh['DBLocusCount'] = self.out_files.first.db_locus_count
        end

        File.open(outfile, 'w') do |out|
          # print the header:
          invariant_ordering.each do |iv|
            out.puts ['H', iv, hh.delete(iv)].join("\t")
          end
          hh.each do |k,v|
            out.puts ['H', k, v].join("\t")
          end
          plural.each do |k,vals|
            vals.each do |val|
              out.puts ['H', k, val].join("\t")
            end
          end

          ##### SPECTRA
          time_to_process = '0.0'
          #########################################
          # NEED TO FIGURE OUT: (in spectra guy)
          #    * Lowest Sp value for top 500 spectra
          #    * Number of sequences matching this precursor ion 
          #########################################

          manual_validation_status = 'U'
          self.out_files.zip(dta_files) do |out_file, dta_file|
            # don't have the time to process (using 0.0 like bioworks 3.2)
            dta_file_mh = dta_file.mh
            out_file_total_inten = out_file.total_inten
            out_file_lowest_sp = out_file.lowest_sp
            if opt[:round]
              dta_file_mh = round(dta_file_mh, mh_dp)
              out_file_total_inten = round(out_file_total_inten, tic_dp)
              out_file_lowest_sp = round(out_file_lowest_sp, sp_dp)
            end

            out.puts ['S', out_file.first_scan, out_file.last_scan, out_file.charge, time_to_process, out_file.computer, dta_file_mh, out_file_total_inten, out_file_lowest_sp, out_file.num_matched_peptides].join("\t")
            out_file.hits.each_with_index do |hit,index|
              hit_mh = hit.mh
              hit_deltacn_orig_updated = hit.deltacn_orig_updated
              hit_xcorr = hit.xcorr
              hit_sp = hit.sp
              if opt[:round]
                hit_mh = round(hit_mh, mh_dp)
                hit_deltacn_orig_updated = round(hit_deltacn_orig_updated, dcn_dp)
                hit_xcorr = round(hit_xcorr, xcorr_dp)
                hit_sp = round(hit_sp, sp_dp)
              end
              # note that the rank is determined by the order..
              out.puts ['M', index+1, hit.rsp, hit_mh, hit_deltacn_orig_updated, hit_xcorr, hit_sp, hit.ions_matched, hit.ions_total, hit.sequence, manual_validation_status].join("\t")
              hit.prots.each do |prot|
                out.puts ['L', prot.first_entry].join("\t")
              end
            end
          end
        end # close the filehandle
      end # method


    end # Srf
  end # Sequest
end # Ms
