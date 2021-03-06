require 'spec_helper'
require 'fileutils'

require 'mspire/sequest/srf'
require 'mspire/sequest/srf/search'

class SRF_TO_MGF_HELPER
  FIRST_MSMS = {
    :first_lines => ['BEGIN IONS', 'TITLE=000.2.2.1.dta', 'CHARGE=1+', 'PEPMASS=391.04541015625'],
    :first_two_ion_lines => ['111.976043701172 41418.0', '112.733383178711 88292.0'],
    :last_two_ion_lines => ['407.412780761719 18959.0', '781.085327148438 10104.0'],
    :last_line => 'END IONS',
  }
  LAST_MSMS = { 
    :first_lines => ['BEGIN IONS', 'TITLE=000.3748.3748.3.dta', 'CHARGE=3+', 'PEPMASS=433.56494129743004'],
    :first_two_ion_lines => ['143.466918945312 2110.0', '151.173095703125 4134.0'],
    :last_two_ion_lines => ['482.678771972656 3357.0', '610.4111328125 8968.0'],
    :last_line => 'END IONS',
  }
end

# these have been checked against Bioworks .dta output
class SRF_TO_DTA_HELPER
  FIRST_SCAN = {
    :first_line => '391.045410 1',
    :first_two_ion_lines => ['111.9760 41418', '112.7334 88292'],
    :last_two_ion_lines => ['407.4128 18959', '781.0853 10104'],
  }
  LAST_SCAN = {
    :first_line => '1298.680271 3',
    :first_two_ion_lines => ['143.4669 2110', '151.1731 4134'],
    :last_two_ion_lines => ['482.6788 3357', '610.4111 8968'],
  }
end

Srf_file = MS::TESTDATA + '/sequest/opd1_static_diff_mods/000.srf'
TMPDIR = TESTFILES + '/tmp'
Mgf_output = TMPDIR + '/000.mgf.tmp'
Dta_output = TMPDIR + '/000.dta.tmp'

shared_examples_for 'an srf to ms2 search converter' do |convert_to_mgf, convert_to_dta|
  def assert_ion_line_close(expected, actual, delta)
    expected.split(/\s+/).zip(actual.split(/\s+/)).each do |exp,act|
      exp.to_f.should be_within(delta).of(act.to_f)
    end
  end

  def compare_dtas(key, filename)
    File.exist?(filename).should be_true
    lines = IO.read(filename).strip.split("\n")
    (exp1, act1) = [key[:first_line], lines[0]].map {|l| l.split(/\s+/) }
    exp1.first.to_f.should be_within(0.000001).of(act1.first.to_f)
    exp1.last.should == act1.last
    (key[:first_two_ion_lines] + key[:last_two_ion_lines]).zip(lines[1,2]+lines[-2,2]) do |exp,act|
      assert_ion_line_close(exp, act, 0.0001)
    end
  end

  def compare_mgfs(key, string_chunk)
    lines = string_chunk.strip.split("\n")
    key[:first_lines][0,3].should == lines[0,3]
    (exp_pair, act_pair) = [key[:first_lines][3], lines[3]].map {|line| line.split('=') }
    exp_pair.first.should == act_pair.first
    exp_pair.last.to_f.should be_within(0.0000001).of( act_pair.last.to_f )

    (key[:first_two_ion_lines] + key[:last_two_ion_lines]).zip(lines[4,2] + lines[-3,2]).each do |exp_line,act_line|
      assert_ion_line_close(exp_line, act_line, 0.00000001)
    end

    key[:last_line].should == lines[-1]
  end

  it 'converts to mgf' do
    output = Mgf_output
    convert_to_mgf.call
    File.exist?(output).should be_true
    output = IO.read(output)
    chunks = output.split("\n\n")

    compare_mgfs(SRF_TO_MGF_HELPER::FIRST_MSMS, chunks.first)
    compare_mgfs(SRF_TO_MGF_HELPER::LAST_MSMS, chunks.last)
  end

  it 'generates .dta files' do
    output = Dta_output
    convert_to_dta.call
    File.exist?(output).should be_true
    File.directory?(output).should be_true
    # frozen (not verified):
    Dir[output + "/*.*"].size.should == 3893 # the correct number files

    compare_dtas(SRF_TO_DTA_HELPER::FIRST_SCAN, output + '/000.2.2.1.dta')
    compare_dtas(SRF_TO_DTA_HELPER::LAST_SCAN, output + '/000.3748.3748.3.dta')
  end

end

describe 'converting an srf to ms2 search format: programmatic' do
  before do
    FileUtils.mkdir(TMPDIR) unless File.exist?(TMPDIR)
  end
  after do
    FileUtils.rmtree(TMPDIR)
  end

  srf = Mspire::Sequest::Srf.new(Srf_file)

  convert_to_mgf = lambda { srf.to_mgf(Mgf_output) }
  convert_to_dta = lambda { srf.to_dta(Dta_output) }

  it_behaves_like 'an srf to ms2 search converter', convert_to_mgf, convert_to_dta

end

describe 'converting an srf to ms2 search format: commandline' do
  def self.commandline_lambda(string)
    lambda { Mspire::Sequest::Srf::Search.commandline(string.split(/\s+/)) }
  end

  convert_to_mgf = self.commandline_lambda "#{Srf_file} -o #{Mgf_output}"
  convert_to_dta = self.commandline_lambda "#{Srf_file} -o #{Dta_output} -f dta"

  before(:each) do
    FileUtils.mkdir(TMPDIR) unless File.exist?(TMPDIR)
  end
  after(:each) do
    FileUtils.rmtree(TMPDIR)
  end

  it_behaves_like 'an srf to ms2 search converter', convert_to_mgf, convert_to_dta
end
