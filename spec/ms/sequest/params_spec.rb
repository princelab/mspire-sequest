require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )

require 'ms/sequest/params'

# returns a hash of all params
def simple_parse(filename)
  hash = {}
  IO.read(filename).split(/\r?\n/).select {|v| v =~ /^[a-z]/}.each do |line|
    if line =~ /([^\s]+)\s*=\s*([^;]+)\s*;?/
      hash[$1.dup] = $2.rstrip
    end
  end
  hash
end

shared 'sequest params' do
  before do
    @obj = Ms::Sequest::Params.new(@file)
  end

  it 'has a method for every parameter in the file' do
    hash = simple_parse(@file)
    hash.each do |k,v|
      @obj.send(k.to_sym).is v
    end
  end

  it 'returns zero length string for params with no information' do
    @obj.second_database_name.is ""
    @obj.sequence_header_filter.is ""
  end

  it 'returns nil for params that do not exist and have no translation' do
    @obj.google_plex.is nil
  end

  it 'provides consistent API between versions for important info' do
    message = capture_stderr do
      @api_hash.each do |k,v|
        @obj.send(k).is v
      end
    end
  end

  it 'provides some backwards compatibility' do
    @backwards_hash.each do |k,v|
      @obj.send(k).is v
    end
  end

end

describe 'sequest params v 3.1' do

  @file = TESTFILES + '/bioworks31.params'
  @api_hash = {
    :version => '3.1',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\ecoli_K12.fasta",
    :enzyme_specificity => [1, 'KR', ''],
    :precursor_mass_type => "average",
    :fragment_mass_type => "average",
    :min_number_termini  => '1',
  }

  @backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '0.0000',
  }

  behaves_like 'sequest params'
end

describe 'sequest params v 3.2' do
  @file = TESTFILES + '/bioworks32.params'
  @api_hash = {
    :version => '3.2',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta",
    :enzyme_specificity => [1, 'KR', 'P'],
    :precursor_mass_type => "average",
    :fragment_mass_type => "average",
    :min_number_termini  => '2',
  }

  @backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '1.0000',
  }

  behaves_like 'sequest params'
end

describe 'sequest params v 3.3' do
  @file = TESTFILES + '/bioworks33.params'
  @api_hash = {
    :version => '3.3',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\yeast.fasta",
    :enzyme_specificity => [1, 'KR', ''],
    :precursor_mass_type => "monoisotopic",
    :fragment_mass_type => "monoisotopic",
    :min_number_termini  => '2',
  }

  @backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '1.0000',
  }
  behaves_like 'sequest params'
end

describe 'sequest params v 3.2 from srf' do
  @file = TESTFILES + '/7MIX_STD_110802_1.sequest_params_fragment.srf'
  @api_hash = {
    :version => '3.2',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\mixed_db_human_ecoli_7prot_unique.fasta",
    :enzyme_specificity => [1, 'KR', 'P'],
    :precursor_mass_type => "average",
    :fragment_mass_type => "average",
    :min_number_termini  => '2',
  }

  @backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '1.0000',
  }
  behaves_like 'sequest params'
end

