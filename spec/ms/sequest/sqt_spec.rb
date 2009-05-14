require File.expand_path( File.dirname(__FILE__) + '/../../tap_spec_helper' )

require File.dirname(__FILE__) + '/sqt_spec_helper'

require 'ms/sequest/sqt'


class ReadingASmallSqtFile < MiniTest::Spec
  before(:each) do
    file = TESTFILES + '/small.sqt'
    @sqt = Ms::Sequest::Sqt.new(file)
  end

  it 'can access header entries like a hash' do
    header = @sqt.header
    HeaderHash.each do |k,v|
      header[k].must_equal v
    end
  end

  it 'can access header entries with methods' do
    header = @sqt.header
    # for example:
    header.database.must_equal HeaderHash['Database']
    # all working:
    HeaderHash.each do |k,v|
      header.send(Ms::Sequest::Sqt::Header::KeysToAtts[k]).must_equal v
    end

  end

  it 'has spectra, matches, and loci' do
    svt = @sqt.spectra[16]
    reply = {:first => @sqt.spectra.first, :last => @sqt.spectra.last, :seventeenth => svt, :first_match_17 => svt.matches.first, :last_match_17 => svt.matches.last, :last_match_17_last_loci => svt.matches.last.loci.last}
    [:first, :last, :seventeenth, :first_match_17, :last_match_17, :last_match_17_last_loci].each do |key|
      TestSpectra[key].each do |k,v|
        if v.is_a? Float
          reply[key].send(k).must_be_close_to(v, 0.0000000001)
        else
          next if key == :last_match_17_last_loci
          #p k
          #p v
          reply[key].send(k).must_equal v
        end
      end
    end
    @sqt.spectra[16].matches.first.loci.size.must_equal 1
    @sqt.spectra[16].matches.last.loci.size.must_equal 1
  end

end

#class SqtGroup_ReadingFiles < MiniTest::Spec
  #before(:each) do
    #file1 = TESTFILES + '/small.sqt'
    #file2 = TESTFILES + '/small2.sqt'
    #@sqg = Ms::Sequest::SqtGroup.new([file1, file2])
  #end

  #it 'has peptide hits' do
    #peps = @sqg.peps
    #peps.size.must_equal 86
    ## first hit in 020
    #peps.first.sequence.must_equal 'R.Y#RLGGS#T#K.K'
    #peps.first.base_name.must_equal 'small'
    ## last hit in 040
    #peps.last.sequence.must_equal 'K.T#IS#S#QK.K'
    #peps.last.base_name.must_equal 'small2'
  #end

  #it 'has prots' do
    ### FROZEN:
    #@sqg.prots.size.must_equal 72
    #sorted = @sqg.prots.sort_by {|v| v.reference }
    #sorted.first.reference.must_equal 'gi|16127996|ref|NP_414543.1|'
    #sorted.first.peps.size.must_equal 33
  #end
#end
