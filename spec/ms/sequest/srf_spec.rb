require 'spec_helper'
require 'ms/sequest/srf_spec_helper' # in spec/

require 'ms/sequest/srf'

require 'fileutils'

include SRFHelper

class Hash
  def object_match(obj)
    self.all? do |k,v|
      k = k.to_sym
      retval = 
        if k == :peaks or k == :hits or k == :proteins
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


shared 'an srf reader' do

  it 'retrieves correct header info' do
    ok @header.object_match(@srf_obj.header)
    ok @dta_gen.object_match(@srf_obj.header.dta_gen)
  end

  # a few more dta params could be added in here:
  it 'retrieves correct dta files' do
    ok @dta_files_first.object_match(@srf_obj.dta_files.first)
    ok @dta_files_last.object_match(@srf_obj.dta_files.last)
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
    ok @out_files_first.object_match(@srf_obj.out_files.first)
    ok @out_files_last.object_match(@srf_obj.out_files.last)
    # first available peptide hit
    ok @out_files_first_pep.object_match(get_first_peps(@srf_obj.out_files).first)
    # last available peptide hit
    ok @out_files_last_pep.object_match(get_first_peps(@srf_obj.out_files.reverse).last)
  end

  it 'retrieves correct params' do
    ok @params.object_match(@srf_obj.params)
  end

  # TODO:
  #it_should 'retrieve probabilities if available'
end

# TODO:, we should try to get some tests with sf values present!


Expected_hash_keys = %w(header dta_gen dta_files_first dta_files_last out_files_first out_files_last out_files_first_pep out_files_last_pep params)

To_run = {
  '3.2' => {:hash => File_32, :file => '/opd1_2runs_2mods/sequest32/020.srf'},
  '3.3' => {:hash => File_33, :file => '/opd1_2runs_2mods/sequest33/020.srf'},
  '3.3.1' => {:hash => File_331, :file => '/opd1_2runs_2mods/sequest331/020.srf'},
}

# I had these nicely combined under RSpec, but this is not as obvious a task
# under minispec given the corrupted include behavior...

describe 'reading srf with duplicate refs v3.2' do

  info = To_run['3.2']
  @file = Ms::TESTDATA + '/sequest' + info[:file]
  @srf_obj = Ms::Sequest::Srf.new(@file)
  Expected_hash_keys.each do |c|
    instance_variable_set("@#{c}", info[:hash][c.to_sym])
  end

  behaves_like 'an srf reader'
end

describe 'reading srf with duplicate refs v3.3' do
  info = To_run['3.3']
  @file = Ms::TESTDATA + '/sequest' + info[:file]
  @srf_obj = Ms::Sequest::Srf.new(@file)
  Expected_hash_keys.each do |c|
    instance_variable_set("@#{c}", info[:hash][c.to_sym])
  end

  behaves_like 'an srf reader'
end

describe 'reading srf with duplicate refs v3.3.1' do
  info = To_run['3.3.1']
  @file = Ms::TESTDATA + '/sequest' + info[:file]
  @srf_obj = Ms::Sequest::Srf.new(@file)
  Expected_hash_keys.each do |c|
    instance_variable_set("@#{c}", info[:hash][c.to_sym])
  end
  behaves_like 'an srf reader'
end

#class SRFReadingACorruptedFile < MiniTest::Spec

#  it 'reads a file from an aborted run w/o failing, but gives warning msg' do
#    srf_file = TESTFILES + '/corrupted_900.srf'
#    message = capture_stderr do
#      srf_obj = Ms::Sequest::Srf.new(srf_file) 
#      srf_obj.base_name.is '900'
#      srf_obj.params.is nil
#      header = srf_obj.header
#      header.db_filename.is "C:\\Xcalibur\\database\\sf_hs_44_36f_longesttrpt.fasta.hdr"
#      header.enzyme.is 'Enzyme:Trypsin(KR) (2)'
#      dta_gen = header.dta_gen
#      dta_gen.start_time.must_be_close_to(1.39999997615814, 0.00000000001)
#      srf_obj.dta_files.is []
#      srf_obj.out_files.is []
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
      #ok File.exist?(srg_file)
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
      #@srf.to_dta
      #ok File.exist?('020')
      #ok File.directory?('020')
      #ok File.exist?('020/020.3366.3366.2.dta')
      #lines = IO.readlines('020/020.3366.3366.2.dta', "\r\n")
      #lines.first.is "1113.106493 2\r\n"
      #lines[1].is "164.5659 4817\r\n"
      
      #FileUtils.rm_rf '020'
    #end
  #end

#end
