require 'spec_helper'

require 'ms/sequest/sqt_spec_helper'
require 'ms/sequest/sqt'

describe 'reading a small sqt file' do

  before do
    file = TESTFILES + '/small.sqt'
    @sqt = MS::Sequest::Sqt.new(file)
  end

  it 'can access header entries like a hash' do
    header = @sqt.header
    HeaderHash.each do |k,v|
      header[k].is v
    end
  end

  it 'can access header entries with methods' do
    header = @sqt.header
    # for example:
    header.database.is HeaderHash['Database']
    # all working:
    HeaderHash.each do |k,v|
      header.send(MS::Sequest::Sqt::Header::KeysToAtts[k]).is v
    end

  end

  it 'has spectra, matches, and loci' do
    svt = @sqt.spectra[16]
    reply = {:first => @sqt.spectra.first, :last => @sqt.spectra.last, :seventeenth => svt, :first_match_17 => svt.matches.first, :last_match_17 => svt.matches.last, :last_match_17_last_loci => svt.matches.last.loci.last}
    [:first, :last, :seventeenth, :first_match_17, :last_match_17, :last_match_17_last_loci].each do |key|
      TestSpectra[key].each do |k,v|
        if v.is_a? Float
          reply[key].send(k).should.be.close(v, 0.0000000001)
        else
          next if key == :last_match_17_last_loci
          #p k
          #p v
          reply[key].send(k).is v
        end
      end
    end
    @sqt.spectra[16].matches.first.loci.size.is 1
    @sqt.spectra[16].matches.last.loci.size.is 1
  end

end

