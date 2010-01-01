require 'tap/task'

module Ms
  module Sequest
    class Srf

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
          srf = Ms::Sequest::Srf.new(srf_file, :link_protein_hits => false, :filter_by_precursor_mass_tolerance => false, :read_pephits => false )
          # options just speed up reading since we don't need .out info anyway
          case format
          when 'mgf'
            srf.to_mgf(newfile)
          when 'dta'
            srf.to_dta(newfile)
          end
        end
      end


    end # Srf
  end # Sequest
end # Ms

