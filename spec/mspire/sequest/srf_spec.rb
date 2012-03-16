require 'spec_helper'
require 'mspire/sequest/srf_spec_helper' # in spec/

require 'mspire/sequest/srf'

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

shared_examples_for 'an srf reader' do |srf_obj, test_hash|

  it 'retrieves correct header info' do
    test_hash[:header].object_match(srf_obj.header).should be_true
    test_hash[:dta_gen].object_match(srf_obj.header.dta_gen).should be_true
  end

  # a few more dta params could be added in here:
  it 'retrieves correct dta files' do
    test_hash[:dta_files_first].object_match(srf_obj.dta_files.first).should be_true
    test_hash[:dta_files_last].object_match(srf_obj.dta_files.last).should be_true
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
    test_hash[:out_files_first].object_match(srf_obj.out_files.first).should be_true
    test_hash[:out_files_last].object_match(srf_obj.out_files.last).should be_true
    # first available peptide hit
    test_hash[:out_files_first_pep].object_match(get_first_peps(srf_obj.out_files).first).should be_true
    # last available peptide hit
    test_hash[:out_files_last_pep].object_match(get_first_peps(srf_obj.out_files.reverse).last).should be_true
  end

  it 'retrieves correct params' do
    test_hash[:params].object_match(srf_obj.params).should be_true
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
  file = MS::TESTDATA + '/sequest' + info[:file]
  srf_obj = Mspire::Sequest::Srf.new(file)

  it_behaves_like 'an srf reader', srf_obj, info[:hash]
end

describe 'reading srf with duplicate refs v3.3' do
  info = To_run['3.3']
  file = MS::TESTDATA + '/sequest' + info[:file]
  srf_obj = Mspire::Sequest::Srf.new(file)

  it_behaves_like 'an srf reader', srf_obj, info[:hash]
end

describe 'reading srf with duplicate refs v3.3.1' do
  info = To_run['3.3.1']
  file = MS::TESTDATA + '/sequest' + info[:file]
  srf_obj = Mspire::Sequest::Srf.new(file)

  it_behaves_like 'an srf reader', srf_obj, info[:hash]
end
