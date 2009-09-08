require File.expand_path( File.dirname(__FILE__) + '/../../tap_spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/srf_spec_helper' )

require 'ms/sequest/srf'

require 'fileutils'

include SRFHelper

class Hash
  def object_match(obj)
    self.all? do |k,v|
      k = k.to_sym
      retval = 
        if k == :peaks or k == :hits or k == :prots
          obj.send(k).size == v
        elsif v.class == Float
          delta = 
            if k == :ppm ; 0.0001          
            else ; 0.0000001          
            end
          (v - obj.send(k)).abs <= delta
        else
          obj.send(k) == v
        end
      if retval == false
        puts "BAD KEY: #{k}"
        puts "need: #{v}"
        puts "got: #{obj.send(k)}"
      end
      retval
    end
  end
end


module SRFReaderBehavior
  extend Shareable

  def initialize(*args)
    super(*args)
    @srf_obj = Ms::Sequest::Srf.new(@file)
  end

  it 'retrieves correct header info' do
    assert @header.object_match(@srf_obj.header)
    assert @dta_gen.object_match(@srf_obj.header.dta_gen)
  end

  # a few more dta params could be added in here:
  it 'retrieves correct dta files' do
    assert @dta_files_first.object_match(@srf_obj.dta_files.first)
    assert @dta_files_last.object_match(@srf_obj.dta_files.last)
  end

  # given an array of out_file objects, returns the first set of hits
  def get_first_peps(out_files)
    out_files.each do |outf|
      if outf.num_hits > 0
        return outf.hits
      end
    end
    return nil
  end

  it 'retrieves correct out files' do
    assert @out_files_first.object_match(@srf_obj.out_files.first)
    assert @out_files_last.object_match(@srf_obj.out_files.last)
    # first available peptide hit
    assert @out_files_first_pep.object_match(get_first_peps(@srf_obj.out_files).first)
    # last available peptide hit
    assert @out_files_last_pep.object_match(get_first_peps(@srf_obj.out_files.reverse).last)
  end

  it 'retrieves correct params' do
    assert @params.object_match(@srf_obj.params)
  end

  # TODO:
  #it_should 'retrieve probabilities if available'
end


Expected_hash_keys = %w(header dta_gen dta_files_first dta_files_last out_files_first out_files_last out_files_first_pep out_files_last_pep params)

To_run = {
  '3.2' => {:hash => File_32, :file => '/opd1_2runs_2mods/sequest32/020.srf'},
  '3.3' => {:hash => File_33, :file => '/opd1_2runs_2mods/sequest33/020.srf'},
  '3.3.1' => {:hash => File_331, :file => '/opd1_2runs_2mods/sequest331/020.srf'},
}

# I had these nicely combined under RSpec, but this is not as obvious a task
# under minispec given the corrupted include behavior...

class SRFReadingWithDuplicateRefs32 < MiniTest::Spec
  include SRFReaderBehavior

  def initialize(*args)
    info = To_run['3.2']
    @file = Ms::TESTDATA + '/sequest' + info[:file]
    Expected_hash_keys.each do |c|
      instance_variable_set("@#{c}", info[:hash][c.to_sym])
    end
    super(*args)
  end
  
end

class SRFReadingWithDuplicateRefs33 < MiniTest::Spec
  include SRFReaderBehavior

  def initialize(*args)
    info = To_run['3.3']
    @file = Ms::TESTDATA + '/sequest' + info[:file]
    Expected_hash_keys.each do |c|
      instance_variable_set("@#{c}", info[:hash][c.to_sym])
    end
    super(*args)
  end
  
end

class SRFReadingWithDuplicateRefs331 < MiniTest::Spec
  include SRFReaderBehavior

  def initialize(*args)
    info = To_run['3.3.1']
    @file = Ms::TESTDATA + '/sequest' + info[:file]
    Expected_hash_keys.each do |c|
      instance_variable_set("@#{c}", info[:hash][c.to_sym])
    end
    super(*args)
  end
  
end

#class SRFReadingACorruptedFile < MiniTest::Spec

#  it 'reads a file from an aborted run w/o failing, but gives warning msg' do
#    srf_file = TESTFILES + '/corrupted_900.srf'
#    message = capture_stderr do
#      srf_obj = Ms::Sequest::Srf.new(srf_file) 
#      srf_obj.base_name.must_equal '900'
#      srf_obj.params.must_equal nil
#      header = srf_obj.header
#      header.db_filename.must_equal "C:\\Xcalibur\\database\\sf_hs_44_36f_longesttrpt.fasta.hdr"
#      header.enzyme.must_equal 'Enzyme:Trypsin(KR) (2)'
#      dta_gen = header.dta_gen
#      dta_gen.start_time.must_be_close_to(1.39999997615814, 0.00000000001)
#      srf_obj.dta_files.must_equal []
#      srf_obj.out_files.must_equal []
#    end
#    message.must_match(/no SEQUEST/i)
#  end
#end

#class SRFGroupCreatingAnSrg < MiniTest::Spec
  #it 'creates one given some non-existing, relative filenames' do 
    ### TEST SRG GROUPING:
    #filenames = %w(my/lucky/filename /another/filename)
    #@srg = SRFGroup.new
    #@srg.filenames = filenames
    #srg_file = TESTFILES + '/tmp_srg_file.srg'
    #begin
      #@srg.to_srg(srg_file)
      #assert File.exist?(srg_file)
    #ensure
      #File.unlink(srg_file)
    #end
  #end
#end


## @TODO: this test needs to be created for a small mock dataset!!
#describe SRF, 'creating dta files' do
  #spec_large do 
    #before(:all) do
      #file = Tfiles_l + '/opd1_2runs_2mods/sequest33/020.srf'
      #@srf = SRF.new(file)
    #end

    #it 'creates dta files' do
      #@srf.to_dta_files
      #assert File.exist?('020')
      #assert File.directory?('020')
      #assert File.exist?('020/020.3366.3366.2.dta')
      #lines = IO.readlines('020/020.3366.3366.2.dta', "\r\n")
      #lines.first.must_equal "1113.106493 2\r\n"
      #lines[1].must_equal "164.5659 4817\r\n"
      
      #FileUtils.rm_rf '020'
    #end
  #end

#end
