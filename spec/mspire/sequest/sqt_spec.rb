require 'spec_helper'

require 'mspire/sequest/sqt_spec_helper'
require 'mspire/sequest/sqt'

describe 'reading a small sqt file' do

  before(:each) do
    file = TESTFILES + '/small.sqt'
    @sqt = Mspire::Sequest::Sqt.new(file)
  end

  it 'can access header entries like a hash' do
    header = @sqt.header
    HeaderHash.each do |k,v|
      header[k].should == v
    end
  end

  it 'can access header entries with methods' do
    header = @sqt.header
    # for example:
    header.database.should == HeaderHash['Database']
    # all working:
    HeaderHash.each do |k,v|
      header.send(Mspire::Sequest::Sqt::Header::KeysToAtts[k]).should == v
    end

  end

  it 'has spectra, matches, and loci' do
    svt = @sqt.spectra[16]
    reply = {:first => @sqt.spectra.first, :last => @sqt.spectra.last, :seventeenth => svt, :first_match_17 => svt.matches.first, :last_match_17 => svt.matches.last, :last_match_17_last_loci => svt.matches.last.loci.last}
    [:first, :last, :seventeenth, :first_match_17, :last_match_17, :last_match_17_last_loci].each do |key|
      TestSpectra[key].each do |k,v|
        if v.is_a? Float
          reply[key].send(k).should be_within(0.0000000001).of(v)
        else
          next if key == :last_match_17_last_loci
          #p k
          #p v
          reply[key].send(k).should == v
        end
      end
    end
    @sqt.spectra[16].matches.first.loci.size.should == 1
    @sqt.spectra[16].matches.last.loci.size.should == 1
  end

end

