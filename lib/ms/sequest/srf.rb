
# standard lib
require 'set'
require 'fileutils'

# other gems
require 'arrayclass'

# in library
require 'ms/id/peptide'
require 'ms/id/protein'
require 'ms/id/search'
require 'ms/sequest/params'

# for conversions
require 'ms/sequest/srf/search'
require 'ms/sequest/srf/sqt'

module Ms ; end
module Ms::Sequest ; end

class Ms::Sequest::Srf
  include Ms::Id::Search

  # inherits peps and prots from Search

  # a String: 3.5, 3.3 or 3.2
  attr_accessor :version

  attr_accessor :header
  attr_accessor :dta_files
  attr_accessor :out_files
  attr_accessor :params
  # a parallel array to dta_files and out_files where each entry is:
  # [first_scan, last_scan, charge]
  attr_accessor :index
  attr_accessor :base_name

  # a boolean to indicate if the results have been filtered by the
  # sequest.params precursor mass tolerance
  attr_accessor :filtered_by_precursor_mass_tolerance 

  def protein_class
    Ms::Sequest::Srf::Out::Prot
  end

  # returns a Sequest::Params object or nil if none
  def self.get_sequest_params(filename)
    # split the file in half and only read the second half (since we can be
    # confident that the params file will be there!)
    File.open(filename) do |handle|
      halfway = handle.stat.size / 2
      handle.seek halfway
      last_half = handle.read
      if sequest_start_index = last_half.rindex('[SEQUEST]')
        params_start_index =  sequest_start_index + halfway
        handle.seek(params_start_index)
        Ms::Sequest::Params.new.parse_io(handle)
      else
        warn "#{filename} has no SEQUEST information, may be a truncated/corrupt file!"
        nil
      end
    end
  end

  def dta_start_byte
    case @version
    when '3.2' ; 3260
    when '3.3' ; 3644
    when '3.5' ; 3644
    end
  end

  # opts:
  #     :filter_by_precursor_mass_tolerance => true | false (default true)
  #     # this will filter by the sequest params prec tolerance as is
  #     # typically done by Bioworks.
  #
  #     :link_protein_hits => true | false (default true)
  #     # if true, generates the @prot attribute for the :prot method
  #     #   and creates one protein per reference that is linked to each 
  #     #   relevant peptide hit.
  #     # if false, each protein for each peptide hit is a unique object 
  #     # and the :prots method returns nil.  If you are merging multiple
  #     # searches then you probably want to set this to false to avoid
  #     # recalculation.
  #
  def initialize(filename=nil, opts={})
    @peps = []

    @dta_files = []
    @out_files = []
    if filename
      from_file(filename, opts)
    end
  end


  # 1. updates the out_file's list of hits based on passing peptides (but not
  # the original hit id; rank is implicit in array ordering)
  # 2. recalculates deltacn values completely if number of hits changed (does
  # not touch deltacn orig)
  #
  # This can spoil proper protein -> peptide linkages.  Ms::Id::Search.merge!
  # should be run after this method to ensure correct protein -> peptide
  # linkages.
  def filter_by_precursor_mass_tolerance!
    pmt = params.peptide_mass_tolerance.to_f
    methd = nil  # the method to 

    case params.peptide_mass_units
    when '0'
      amu_based = true
      milli_amu = false
    when '1'
      amu_based = true
      milli_amu = true
    when '2'
      amu_based = false
    end

    self.filtered_by_precursor_mass_tolerance = true
    self.out_files.each do |out_file|
      hits = out_file.hits
      before = hits.size
      hits.reject! do |pep|
        if amu_based
          if milli_amu
            (pep.deltamass.abs > (pmt/1000))
          else
            (pep.deltamass.abs > pmt)
          end
        else
          (pep.ppm.abs > pmt)
        end
      end
      if hits.size != before
        out_file.hits = hits # <- is this necessary 
        Ms::Sequest::Srf::Out::Pep.update_deltacns_from_xcorr(hits)
        out_file.num_hits = hits.size
      end
    end
    self
  end

  # returns self
  # opts are the same as for 'new'
  def from_file(filename, opts)
    opts = { :filter_by_precursor_mass_tolerance => true, :link_protein_hits => true}.merge(opts)
    params = Ms::Sequest::Srf.get_sequest_params(filename)
    dups_gt_0 = false
    if params
      dups = params.print_duplicate_references
      if dups == '0'
        warn <<END
***************************************************************************
For complete protein <=> peptide linkages, .srf files must be created with
print_duplicate_references > 0. To capture all duplicate references, set the
sequest parameter 'print_duplicate_references' to 100 or greater.
***************************************************************************
END
      else
        dups_gt_0 = true
      end
    else
    end

    File.open(filename, "rb") do |fh|
      @header = Ms::Sequest::Srf::Header.new.from_io(fh)      
      @version = @header.version

      unpack_35 = case @version
                  when '3.2'
                    false
                  when '3.3'
                    false
                  when '3.5'
                    true
                  end
      @dta_files, measured_mhs = read_dta_files(fh,@header.num_dta_files, unpack_35)

      @out_files = read_out_files(fh,@header.num_dta_files, measured_mhs, unpack_35)
      if fh.eof?
        #warn "FILE: '#{filename}' appears to be an abortive run (no params in srf file)\nstill continuing..."
        @params = nil
        @index = []
      else
        @params = Ms::Sequest::Params.new.parse_io(fh)
        # This is very sensitive to the grab_params method in sequest params
        fh.read(12)  ## gap between last params entry and index 
        @index = read_scan_index(fh,@header.num_dta_files)
      end
    end


    ### UPDATE SOME THINGS:
    @base_name = @header.raw_filename.scan(/[\\\/]([^\\\/]+)\.RAW$/).first.first
    # give each hit a base_name, first_scan, last_scan
    @index.each_with_index do |ind,i|
      mass_measured = @dta_files[i][0]
      @out_files[i][0,3] = *ind
      pep_hits = @out_files[i][6]
      @peps.push( *pep_hits )
      pep_hits.each do |pep_hit|
        pep_hit[14,4] = @base_name, *ind
        # add the deltamass
        pep_hit[11] = pep_hit[0] - mass_measured  # real - measured (deltamass)
        pep_hit[12] = 1.0e6 * pep_hit[11].abs / mass_measured ## ppm
        pep_hit[18] = self  ## link with the srf object
        if pep_hit.first_scan == 5719
          puts [pep_hit.sequence, pep_hit.xcorr].join(' ')
        end
      end
    end

    filter_by_precursor_mass_tolerance! if params

    if opts[:link_protein_hits]
      (@peps, @prots) = merge!([peps]) do |_prot, _peps|
        prot = Ms::Sequest::Srf::Out::Prot.new(_prot.reference, _peps)
      end
    end

    self
  end

  # returns an index where each entry is [first_scan, last_scan, charge]
  def read_scan_index(fh, num)
    ind_len = 24
    index = Array.new(num)
    unpack_string = 'III'
    st = ''
    ind_len.times do st << '0' end  ## create a 24 byte string to receive data
    num.times do |i|
      fh.read(ind_len, st)
      index[i] = st.unpack(unpack_string)
    end
    index
  end

  # returns an array of dta_files
  def read_dta_files(fh, num_files, unpack_35)
    measured_mhs = Array.new(num_files) ## A parallel array to capture the actual mh
    dta_files = Array.new(num_files)
    start = dta_start_byte
    unless fh.pos == start
      fh.pos = start
    end

    header.num_dta_files.times do |i|
      dta_file = Ms::Sequest::Srf::DTA.new.from_io(fh, unpack_35) 
      measured_mhs[i] = dta_file[0]
      dta_files[i] = dta_file
    end
    [dta_files, measured_mhs]
  end

  # filehandle (fh) must be at the start of the outfiles.  'read_dta_files'
  # will put the fh there.
  def read_out_files(fh,number_files, measured_mhs, unpack_35)
    out_files = Array.new(number_files)
    header.num_dta_files.times do |i|
      out_files[i] = Ms::Sequest::Srf::Out.new.from_io(fh, unpack_35)
    end
    out_files
  end

end

class Ms::Sequest::Srf::Header

  Start_byte = {
    :enzyme => 438,
    :ion_series => 694,
    :model => 950,
    :modifications => 982,
    :raw_filename => 1822,
    :db_filename => 2082,
    :dta_log_filename => 2602,
    :params_filename => 3122,
    :sequest_log_filename => 3382,
  }
  Byte_length = {
    :enzyme => 256,
    :ion_series => 256,
    :model => 32,
    :modifications => 840,
    :raw_filename => 260,
    :db_filename => 520,
    :dta_log_filename => 520,
    :params_filename => 260,
    :sequest_log_filename => 262, ## is this really 262?? or should be 260??
  }
  Byte_length_v32 = {
    :modifications => 456,
  }

  # a Ms::Sequest::Srf::DTAGen object
  attr_accessor :version
  attr_accessor :dta_gen
  attr_accessor :enzyme
  attr_accessor :ion_series
  attr_accessor :model
  attr_accessor :modifications
  attr_accessor :raw_filename
  attr_accessor :db_filename
  attr_accessor :dta_log_filename
  attr_accessor :params_filename
  attr_accessor :sequest_log_filename

  def num_dta_files
    @dta_gen.num_dta_files
  end

  # sets fh to 0 and grabs the information it wants
  def from_io(fh)
    st = fh.read(4) 
    @version = '3.' + st.unpack('I').first.to_s
    @dta_gen = Ms::Sequest::Srf::DTAGen.new.from_io(fh)

    ## get the rest of the info
    byte_length = Byte_length.dup
    byte_length.merge! Byte_length_v32 if @version == '3.2'

    fh.pos = Start_byte[:enzyme]
    [:enzyme, :ion_series, :model, :modifications, :raw_filename, :db_filename, :dta_log_filename, :params_filename, :sequest_log_filename].each do |param|
      send("#{param}=".to_sym, get_null_padded_string(fh, byte_length[param]) )
    end
    self
  end

  private
  def get_null_padded_string(fh,bytes)
    st = fh.read(bytes)
    # for empty declarations
    if st[0] == 0x000000
      return ''
    end
    st.rstrip!
    st
  end


end

# the DTA Generation Params
class Ms::Sequest::Srf::DTAGen

  ## not sure if this is correct
  # Float
  attr_accessor :start_time
  # Float
  attr_accessor :start_mass
  # Float
  attr_accessor :end_mass
  # Integer
  attr_accessor :num_dta_files
  # Integer
  attr_accessor :group_scan
  ## not sure if this is correct
  # Integer
  attr_accessor :min_group_count
  # Integer
  attr_accessor :min_ion_threshold
  #attr_accessor :intensity_threshold # can't find yet
  #attr_accessor :precursor_tolerance # can't find yet
  # Integer
  attr_accessor :start_scan
  # Integer
  attr_accessor :end_scan

  # 
  def from_io(fh)
    fh.pos = 0 if fh.pos != 0  
    st = fh.read(148)
    (@start_time, @start_mass, @end_mass, @num_dta_files, @group_scan, @min_group_count, @min_ion_threshold, @start_scan, @end_scan) = st.unpack('x36ex12ex4ex48Ix12IIIII')
    self
  end
end

# total_num_possible_charge_states is not correct under 3.5 (Bioworks 3.3.1)
# unknown is, well unknown...

Ms::Sequest::Srf::DTA = Arrayclass.new( %w(mh dta_tic num_peaks charge ms_level unknown total_num_possible_charge_states peaks) )

class Ms::Sequest::Srf::DTA 
  # original
  # Unpack = "EeIvvvv"
  Unpack_32 = "EeIvvvv"
  Unpack_35 = "Ex8eVx2vvvv"


  # note on peaks (self[7])
  # this is a byte array of floats, you can get the peaks out with
  # unpack("e*")

  undef_method :inspect
  def inspect
    peaks_st = 'nil'
    if self[7] ; peaks_st = "[#{self[7].size} bytes]" end
    "<Ms::Sequest::Srf::DTA @mh=#{mh} @dta_tic=#{dta_tic} @num_peaks=#{num_peaks} @charge=#{charge} @ms_level=#{ms_level} @total_num_possible_charge_states=#{total_num_possible_charge_states} @peaks=#{peaks_st} >"
  end

  def from_io(fh, unpack_35)
    if unpack_35
      @unpack = Unpack_35
      @read_header = 34
      @read_spacer = 22
    else
      @unpack = Unpack_32
      @read_header = 24
      @read_spacer = 24
    end

    st = fh.read(@read_header)
    # get the bulk of the data in single unpack
    self[0,7] = st.unpack(@unpack)

    # Scan numbers are given at the end in an index!
    st2 = fh.read(@read_spacer)

    num_bytes_to_read = num_peaks * 8  
    st3 = fh.read(num_bytes_to_read)
    self[7] = st3
    self
  end

  def to_dta_file_data
    string = "#{round(mh, 6)} #{charge}\r\n"
    peak_ar = peaks.unpack('e*')
    (0...(peak_ar.size)).step(2) do |i|
      # %d is equivalent to floor, so we round by adding 0.5!
      string << "#{round(peak_ar[i], 4)} #{(peak_ar[i+1] + 0.5).floor}\r\n"
      #string << peak_ar[i,2].join(' ') << "\r\n"
    end
    string
  end

  # write a class dta file to the io object
  def write_dta_file(io)
    io.print to_dta_file_data
  end

  def round(float, decimal_places)
    sprintf("%.#{decimal_places}f", float)
  end

end


Ms::Sequest::Srf::Out = Arrayclass.new( %w(first_scan last_scan charge num_hits computer date_time hits total_inten lowest_sp num_matched_peptides db_locus_count) )

# 0=first_scan, 1=last_scan, 2=charge, 3=num_hits, 4=computer, 5=date_time, 6=hits, 7=total_inten, 8=lowest_sp, 9=num_matched_peptides, 10=db_locus_count

class Ms::Sequest::Srf::Out
  Unpack_32 = '@36vx2Z*@60Z*'
  Unpack_35 = '@36vx4Z*@62Z*'

  undef_method :inspect
  def inspect
    hits_s = 
      if self[6]
        ", @hits(#)=#{hits.size}"
      else
        ''
      end
    "<Ms::Sequest::Srf::Out  first_scan=#{first_scan}, last_scan=#{last_scan}, charge=#{charge}, num_hits=#{num_hits}, computer=#{computer}, date_time=#{date_time}#{hits_s}>"
  end

  def from_io(fh, unpack_35)
    ## EMPTY out file is 96 bytes
    ## each hit is 320 bytes
    ## num_hits and charge:
    st = fh.read(96)

    self[3,3] = st.unpack( (unpack_35 ? Unpack_35 : Unpack_32) )
    self[7,4] = st.unpack('@8eex4Ix4I')
    num_hits = self[3]

    ar = Array.new(num_hits)
    if ar.size > 0
      num_extra_references = 0
      num_hits.times do |i|
        ar[i] = Ms::Sequest::Srf::Out::Pep.new.from_io(fh, unpack_35)
        num_extra_references += ar[i].num_other_loci
      end
      Ms::Sequest::Srf::Out::Pep.read_extra_references(fh, num_extra_references, ar)
      ## The xcorrs are already ordered by best to worst hit
      ## ADJUST the deltacn's to be meaningful for the top hit:
      ## (the same as bioworks and prophet)
      Ms::Sequest::Srf::Out::Pep.set_deltacn_from_deltacn_orig(ar)
      #puts ar.map  {|a| a.deltacn }.join(", ")
    end
    self[6] = ar
    self
  end



end


# deltacn_orig - the one that sequest originally reports (top hit gets 0.0)
# deltacn - modified to be that of the next best hit (by xcorr) and the last
# hit takes 1.1.  This is what is called deltacn by bioworks and pepprophet
# (at least for the first few years).  If filtering occurs, it will be
# updated.  
# deltacn_orig_updated - the latest updated value of deltacn.
# Originally, this will be equal to deltacn_orig.  After filtering, this will
# be recalculated.  To know if this will be different from deltacn_orig, query
# match.srf.filtered_by_precursor_mass_tolerance.  If this is changed, then
# deltacn should also be changed to reflect it. 
# mh - the theoretical mass + h
# prots are created as SRF prot objects with a reference and linked to their
# peptides (from global hash by reference)
# ppm = 10^6 * ∆m_accuracy / mass_measured  [ where ∆m_accuracy = mass_real – mass_measured ]
# This is calculated for the M+H mass!
# num_other_loci is the number of other loci that the peptide matches beyond
# the first one listed
# srf = the srf object this scan came from


Ms::Sequest::Srf::Out::Pep = Arrayclass.new( %w(mh deltacn_orig sp xcorr id num_other_loci rsp ions_matched ions_total sequence prots deltamass ppm aaseq base_name first_scan last_scan charge srf deltacn deltacn_orig_updated) )
# 0=mh 1=deltacn_orig 2=sp 3=xcorr 4=id 5=num_other_loci 6=rsp 7=ions_matched 8=ions_total 9=sequence 10=prots 11=deltamass 12=ppm 13=aaseq 14=base_name 15=first_scan 16=last_scan 17=charge 18=srf 19=deltacn 20=deltacn_orig_updated

class Ms::Sequest::Srf::Out::Pep
  #include SpecID::Pep

  # creates the deltacn that is meaningful for the top hit (the deltacn_orig
  # or the second best hit and so on).
  # assumes sorted
  def self.set_deltacn_from_deltacn_orig(ar)
    (1...ar.size).each {|i| ar[i-1].deltacn = ar[i].deltacn_orig }
    ar[-1].deltacn = 1.1
  end

  # (assumes sorted)
  # recalculates deltacn from xcorrs and sets deltacn_orig_updated and deltacn
  def self.update_deltacns_from_xcorr(ar)
    if ar.size > 0
      top_score = ar.first[3]
      other_scores = (1...(ar.size)).to_a.map do |i|
        1.0 - (ar[i][3]/top_score)
      end
      ar.first[20] = 0.0
      (0...(ar.size-1)).each do |i|
        ar[i][19] = other_scores[i]    # deltacn
        ar[i+1][20] = other_scores[i]  # deltacn_orig_updated
      end
      ar.last[19] = 1.1
    end
  end

  def self.read_extra_references(fh, num_extra_references, pep_hits)
    num_extra_references.times do
      # 80 bytes total (with index number)
      pep = pep_hits[fh.read(8).unpack('x4I').first - 1]

      ref = fh.read(80).unpack('A*').first
      pep[10] << Ms::Sequest::Srf::Out::Prot.new(ref[0,38])
    end
    #  fh.read(6) if unpack_35
  end

  # x2=???
  #Unpack_35 = '@64Ex8ex12eeIx22vx2vvx8Z*@246Z*'
  ### NOTE: 
  # I need to verify that this is correct (I mean the 'I' after x18)
  Unpack_35 = '@64Ex8ex12eeIx18Ivx2vvx8Z*@246Z*'
  # translation: @64=(64 bytes in to the record), E=mH, x8=8unknown bytes, e=deltacn,
  # x12=12unknown bytes, e=sp, e=xcorr, I=ID#, x18=18 unknown bytes, v=rsp,
  # v=ions_matched, v=ions_total, x8=8unknown bytes, Z*=sequence, 240Z*=at
  # byte 240 grab the string (which is proteins).
  #Unpack_32 = '@64Ex8ex12eeIx18vvvx8Z*@240Z*'
  Unpack_32 = '@64Ex8ex12eeIx14Ivvvx8Z*@240Z*'
  Unpack_four_null_bytes = 'a*'
  Unpack_Zstar = 'Z*'
  Read_35 = 426
  Read_32 = 320

  FourNullBytes_as_string = "\0\0\0\0"
  #NewRecordStart = "\0\0" + 0x3a.chr + 0x1a.chr + "\0\0"
  NewRecordStart = 0x01.chr + 0x00.chr
  Sequest_record_start = "[SEQUEST]"

  undef_method :inspect
  def inspect
    st = %w(aaseq sequence mh deltacn_orig sp xcorr id rsp ions_matched ions_total prots deltamass ppm base_name first_scan last_scan charge deltacn).map do |v| 
      if v == 'prots'
        "#{v}(#)=#{send(v.to_sym).size}"
      elsif v.is_a? Array
        "##{v}=#{send(v.to_sym).size}"
      else
        "#{v}=#{send(v.to_sym).inspect}"
      end
    end
    st.unshift("<#{self.class}")
    if srf
      st.push("srf(base_name)=#{srf.base_name.inspect}")
    end
    st.push('>')
    st.join(' ')
    #"<Ms::Sequest::Srf::Out::Pep @mh=#{mh}, @deltacn=#{deltacn}, @sp=#{sp}, @xcorr=#{xcorr}, @id=#{id}, @rsp=#{rsp}, @ions_matched=#{ions_matched}, @ions_total=#{ions_total}, @sequence=#{sequence}, @prots(count)=#{prots.size}, @deltamass=#{deltamass}, @ppm=#{ppm} @aaseq=#{aaseq}, @base_name=#{base_name}, @first_scan=#{first_scan}, @last_scan=#{last_scan}, @charge=#{charge}, @srf(base_name)=#{srf.base_name}>"
  end
  # extra_references_array is an array that grows with peptides as extra
  # references are discovered.
  def from_io(fh, unpack_35)
    unpack = 
      if unpack_35 ; Unpack_35
      else ; Unpack_32
      end

    ## get the first part of the info
    st = fh.read(( unpack_35 ? Read_35 : Read_32) ) ## read all the hit data

    self[0,10] = st.unpack(unpack)

    # set deltacn_orig_updated 
    self[20] = self[1]

    # we are slicing the reference to 38 chars to be the same length as
    # duplicate references
    self[10] = [Ms::Sequest::Srf::Out::Prot.new(self[10][0,38])]

    self[13] = Ms::Id::Peptide.sequence_to_aaseq(self[9])

    fh.read(6) if unpack_35

    self
  end

end


Ms::Sequest::Srf::Out::Prot = Arrayclass.new( %w(reference peps) )

class Ms::Sequest::Srf::Out::Prot
  include Ms::Id::Protein
  ## we shouldn't have to do this because this is inlcuded in SpecID::Prot, but
  ## under some circumstances it won't work without explicitly calling it.
  #include ProteinReferenceable 

  tmp = $VERBOSE ; $VERBOSE = nil
  def initialize(reference=nil, peps=[])
    #super(@@arr_size)
    super(self.class.size)
    #@reference = reference
    #@peps = peps
    self[0,2] = reference, peps
  end
  $VERBOSE = tmp

  #  "<Ms::Sequest::Srf::Out::Prot reference=\"#{@reference}\">"

  undef_method :inspect
  def inspect
    "<Ms::Sequest::Srf::Out::Prot @reference=#{reference}, @peps(#)=#{peps.size}>"
  end
end

class Ms::Sequest::SrfGroup 
  include Ms::Id::SearchGroup

  # inherets an array of Ms::Sequest::Srf::Out::Pep objects
  # inherets an array of Ms::Sequest::Srf::Out::Prot objects

  # see Ms::Id::Search for acceptable arguments
  # (filename, filenames, array of objects)
  # opts = 
  #     :filter_by_precursor_mass_tolerance => true | false (default true)
  def initialize(arg, opts={}, &block)
    orig_opts = opts.dup
    indiv_opts = { :link_protein_hits => false }
    super(arg, opts.merge(indiv_opts)) do
      unless orig_opts[:link_protein_hits] == false
        puts "MERGING GROUP!"
        (@peps, @prots) = merge!(@searches.map {|v| v.peps }) do |_prot, _peps|
          Ms::Sequest::Srf::Out::Prot.new(_prot.reference, _peps)
        end
      end
    end
    block.call(self) if block_given?
  end

  def search_class
    Ms::Sequest::Srf
  end

  # returns the filename used
  # if the file exists, the name will be expanded to full path, otherwise just
  # what is given
  def to_srg(srg_filename='bioworks.srg')
    File.open(srg_filename, 'w') do |v|
      @filenames.each do |srf_file|
        if File.exist? srf_file
          v.puts File.expand_path(srf_file)
        else
          v.puts srf_file
        end
      end
    end
    srg_filename
  end
end





