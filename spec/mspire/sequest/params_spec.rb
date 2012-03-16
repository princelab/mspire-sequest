require 'spec_helper'

require 'mspire/sequest/params'

# returns a hash of all params
def simple_parse(filename)
  hash = {}
  data = File.open(filename) do |io| 
    # this makes it work with ruby 1.9:
    io.set_encoding("ASCII-8BIT") if io.respond_to?(:set_encoding)
    io.read 
  end
  data.split(/\r?\n/).select {|v| v =~ /^[a-z]/}.each do |line|
    if line =~ /([^\s]+)\s*=\s*([^;]+)\s*;?/
      hash[$1.dup] = $2.rstrip
    end
  end
  hash
end

shared_examples_for 'sequest params' do |params_file, api_hash, backwards_hash|

  subject { Mspire::Sequest::Params.new(params_file) }

  it 'has a method for every parameter in the file' do
    hash = simple_parse(params_file)
    hash.each do |k,v|
      subject.send(k.to_sym).should == v
    end
  end

  it 'returns zero length string for params with no information' do
    subject.second_database_name.should == ""
    subject.sequence_header_filter.should == ""
  end

  it 'returns nil for params that do not exist and have no translation' do
    subject.google_plex.should == nil
  end

  it 'provides consistent API between versions for important info' do
    message = capture_stderr do
      api_hash.each do |k,v|
        subject.send(k).should == v
      end
    end
  end

  it 'provides some backwards compatibility' do
    backwards_hash.each do |k,v|
      subject.send(k).should == v
    end
  end

end

describe 'sequest params v 3.1' do

  file = TESTFILES + '/bioworks31.params'
  api_hash = {
    :version => '3.1',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\ecoli_K12.fasta",
    :enzyme_specificity => [1, 'KR', ''],
    :precursor_mass_type => "average",
    :fragment_mass_type => "average",
    :min_number_termini  => '1',
  }

  backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '0.0000',
  }

  it_behaves_like 'sequest params', file, api_hash, backwards_hash
end

describe 'sequest params v 3.2' do
  file = TESTFILES + '/bioworks32.params'
  api_hash = {
    :version => '3.2',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta",
    :enzyme_specificity => [1, 'KR', 'P'],
    :precursor_mass_type => "average",
    :fragment_mass_type => "average",
    :min_number_termini  => '2',
  }

  backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '1.0000',
  }

  it_behaves_like 'sequest params', file, api_hash, backwards_hash 
end

describe 'sequest params v 3.3' do
  file = TESTFILES + '/bioworks33.params'
  api_hash = {
    :version => '3.3',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\yeast.fasta",
    :enzyme_specificity => [1, 'KR', ''],
    :precursor_mass_type => "monoisotopic",
    :fragment_mass_type => "monoisotopic",
    :min_number_termini  => '2',
  }

  backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '1.0000',
  }
  it_behaves_like 'sequest params', file, api_hash, backwards_hash
end

describe 'sequest params v 3.2 from srf' do
  file = TESTFILES + '/7MIX_STD_110802_1.sequest_params_fragment.srf'
  api_hash = {
    :version => '3.2',
    :enzyme => 'Trypsin',
    :database => "C:\\Xcalibur\\database\\mixed_db_human_ecoli_7prot_unique.fasta",
    :enzyme_specificity => [1, 'KR', 'P'],
    :precursor_mass_type => "average",
    :fragment_mass_type => "average",
    :min_number_termini  => '2',
  }

  backwards_hash = {
    :max_num_internal_cleavages => '2',
    :fragment_ion_tol => '1.0000',
  }
  it_behaves_like 'sequest params', file, api_hash, backwards_hash 
end

