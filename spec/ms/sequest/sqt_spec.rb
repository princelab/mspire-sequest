require File.expand_path( File.dirname(__FILE__) + '/../../tap_spec_helper' )

require 'ms/sequest/sqt'

HeaderHash = {}
header_doublets = [
  %w(SQTGenerator	mspire),
  %w(SQTGeneratorVersion	0.3.1),
  %w(Database	C:\Xcalibur\database\ecoli_K12_ncbi_20060321.fasta),
  %w(FragmentMasses	AVG),
  %w(PrecursorMasses	AVG),
  ['StartTime', ''],
  ['Alg-MSModel', 'LCQ Deca XP'],
  %w(DBLocusCount	4237),
  %w(Alg-FragMassTol	1.0000),
  %w(Alg-PreMassTol	25.0000),
  ['Alg-IonSeries', '0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0'],
  %w(Alg-PreMassUnits	ppm),
  ['Alg-Enzyme', 'Trypsin(KR/P) (2)'],

  ['Comment', ['ultra small file created for testing', 'Created from Bioworks .srf file']],
  ['DynamicMod', ['M*=+15.99940', 'STY#=+79.97990']],
  ['StaticMod', []],
].each do |double|
  HeaderHash[double[0]] = double[1]
end

TestSpectra = {
  :first => { :first_scan=>2, :last_scan=>2, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>390.92919921875, :total_intensity=>2653.90307617188, :lowest_sp=>0.0, :num_matched_peptides=>0, :matches=>[]},
  :last => { :first_scan=>27, :last_scan=>27, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>393.008056640625, :total_intensity=>2896.16967773438, :lowest_sp=>0.0, :num_matched_peptides=>0, :matches=>[] },
  :seventeenth => {:first_scan=>23, :last_scan=>23, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>1022.10571289062, :total_intensity=>3637.86059570312, :lowest_sp=>0.0, :num_matched_peptides=>41},
  :first_match_17 => { :rxcorr=>1, :rsp=>5, :mh=>1022.11662242, :deltacn_orig=>0.0, :xcorr=>0.725152492523193, :sp=>73.9527359008789, :ions_matched=>6, :ions_total=>24, :sequence=>"-.MGT#TTM*GVK.L", :manual_validation_status=>"U", :first_scan=>23, :last_scan=>23, :charge=>1, :deltacn=>0.0672458708286285, :aaseq => 'MGTTTMGVK' },
  :last_match_17 => {:rxcorr=>10, :rsp=>16, :mh=>1022.09807242, :deltacn_orig=>0.398330867290497, :xcorr=>0.436301857233047, :sp=>49.735767364502, :ions_matched=>5, :ions_total=>21, :sequence=>"-.MRT#TSFAK.V", :manual_validation_status=>"U", :first_scan=>23, :last_scan=>23, :charge=>1, :deltacn=>1.1, :aaseq => 'MRTTSFAK'},
  :last_match_17_last_loci => {:reference =>'gi|16129390|ref|NP_415948.1|', :first_entry =>'gi|16129390|ref|NP_415948.1|', :locus =>'gi|16129390|ref|NP_415948.1|', :description => 'Fake description' }
}


class ReadingASmallSQTFile < MiniTest::Spec
  before(:each) do
    file = TESTFILES + '/small.sqt'
    @sqt = Ms::Sequest::SQT.new(file)
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
      header.send(Ms::Sequest::SQT::Header::KeysToAtts[k]).must_equal v
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
          reply[key].send(k).must_equal v
        end
      end
    end
    @sqt.spectra[16].matches.first.loci.size.must_equal 1
    @sqt.spectra[16].matches.last.loci.size.must_equal 1
  end

end

class SQTGroup_ReadingFiles < MiniTest::Spec
  before(:each) do
    file1 = TESTFILES + '/small.sqt'
    file2 = TESTFILES + '/small2.sqt'
    @sqg = Ms::Sequest::SQTGroup.new([file1, file2])
  end

  it 'has peptide hits' do
    peps = @sqg.peps
    peps.size.must_equal 86
    # first hit in 020
    peps.first.sequence.must_equal 'R.Y#RLGGS#T#K.K'
    peps.first.base_name.must_equal 'small'
    # last hit in 040
    peps.last.sequence.must_equal 'K.T#IS#S#QK.K'
    peps.last.base_name.must_equal 'small2'
  end

  it 'has prots' do
    ## FROZEN:
    @sqg.prots.size.must_equal 72
    sorted = @sqg.prots.sort_by {|v| v.reference }
    sorted.first.reference.must_equal 'gi|16127996|ref|NP_414543.1|'
    sorted.first.peps.size.must_equal 33
  end
end
