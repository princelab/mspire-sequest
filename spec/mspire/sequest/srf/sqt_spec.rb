require 'spec_helper'

require 'mspire/sequest/srf'
require 'mspire/sequest/srf/sqt'

SpecHelperHeaderHash = {
  'SQTGenerator' => 'mspire: ms-sequest',
  'SQTGeneratorVersion' => String,
  'Database' => 'C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta',
  'FragmentMasses' => 'AVG',
  'PrecursorMasses' => 'AVG',
  'StartTime' => nil, 
  'Alg-MSModel' => 'LCQ Deca XP',
  'Alg-PreMassUnits' => 'amu',
  'DBLocusCount' => '4237',
  'Alg-FragMassTol' => '1.0000',
  'Alg-PreMassTol' => '1.4000',
  'Alg-IonSeries' => '0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0',
  'Alg-Enzyme' => 'Trypsin(KR/P) (2)',
  'Comment' => ['Created from Bioworks .srf file'],
  'DynamicMod' => ['STY*=+79.97990', 'M#=+14.02660'],
}

ExpasyStaticMods = ['C=160.1901','Cterm=10.1230','E=161.4455']
MoleculesStaticMods = ["C=160.1942", "Cterm=10.1230", "E=161.44398"]
SpecHelperHeaderHash['StaticMod'] = MoleculesStaticMods 

# these only need to be really close
Close_indices = {
  'S' => [6,7],
  'M' => [3,4,5,6],
}

SpecHelperOtherLines =<<END
S	2	2	1	0.0	VELA	391.04541015625	3021.5419921875	0.0	0
S	3	3	1	0.0	VELA	446.009033203125	1743.96911621094	0.0	122
M	1	1	445.5769264522	0.0	0.245620265603065	16.6666660308838	1	6	R.SNSK.S	U
L	gi|16128266|ref|NP_414815.1|
END

SpecHelperOtherLinesEnd =<<END
L	gi|90111093|ref|NP_414704.4|
M	10	17	1298.5350544522	0.235343858599663	0.823222815990448	151.717300415039	12	54	K.LQKIITNSY*K	U
L	gi|90111124|ref|NP_414904.2|
END


module SPEC
  Srf_file = MS::TESTDATA + '/sequest/opd1_static_diff_mods/000.srf' 
  TMPDIR = TESTFILES + '/tmp'
  Srf_output = TMPDIR + '/000.sqt.tmp'
end


# {
#   :lambdas => { :basic_conversion, :with_new_db_path, :update_the_db_path }
#   :original_db_filename = String
#                        # "C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta"
#   :output => String  # SPEC::Srf_output
# }

shared_examples_for 'an srf to sqt converter' do |opts|

  # returns true or false
  def header_hash_match(header_lines, hash)
    header_lines.all? do |line|
      (h, k, v) = line.chomp.split("\t")
      if hash[k].is_a? Array
        if hash[k].include?(v) 
          true
        else
          puts "FAILED: "
          p k
          p v
          p hash[k]
          false
        end
      elsif hash[k] == String
        v.is_a?(String)
      else
        if v == hash[k]
          true
        else
          puts "FAILED: "
          p k
          p v
          p hash[k]
          false
        end
      end
    end
  end

  def sqt_line_match(act_line_ar, exp_line_ar)
    exp_line_ar.zip(act_line_ar) do |exp_line, act_line|
      (e_pieces, a_pieces) = [exp_line, act_line].map {|line| line.chomp.split("\t") } 
      if %w(S M).include?(k = e_pieces[0])
        (e_close, a_close) = [e_pieces, a_pieces].map do |pieces| 
          Close_indices[k].sort.reverse.map do |i|
            pieces.delete_at(i).to_f
          end.reverse
        end
        e_close.zip(a_close) do |ex, ac|
          ex.should be_within(0.0000001).of( ac )
        end
      end
      e_pieces.should == a_pieces
    end
  end

  it 'converts without bothering with the database' do
    opts[:lambdas][:basic_conversion].call
    File.exist?(opts[:output]).should be_true
    lines = File.readlines(opts[:output])
    lines.size.should == 80910
    header_lines = lines.grep(/^H/)
    (header_lines.size > 10).should be_true
    header_hash_match(header_lines, SpecHelperHeaderHash).should be_true
    other_lines = lines.grep(/^[^H]/)

    sqt_line_match(other_lines[0,4], SpecHelperOtherLines.strip.split("\n"))
    sqt_line_match(other_lines[-3,3], SpecHelperOtherLinesEnd.strip.split("\n"))

    File.unlink(opts[:output]) rescue false
  end

  it 'can get db info with correct path' do
    opts[:lambdas][:with_new_db_path].call
    File.exist?(opts[:output]).should be_true
    lines = IO.readlines(opts[:output])
    has_md5 = lines.any? do |line|
      line =~ /DBMD5Sum\s+202b1d95e91f2da30191174a7f13a04e/
    end
    has_md5.should be_true

    has_seq_len = lines.any? do |line|
      # frozen
      line =~ /DBSeqLength\s+1342842/
    end
    has_seq_len.should be_true
    lines.size.should == 80912
    File.unlink(opts[:output]) rescue false
  end

  it 'can update the Database' do
    opts[:lambdas][:update_the_db_path].call
    regexp = Regexp.new("Database\t/.*/opd1_2runs_2mods/sequest33/ecoli_K12_ncbi_20060321.fasta")
    updated_db = IO.readlines(opts[:output]).any? do |line|
      line =~ regexp
    end
    updated_db.should be_true
    File.unlink(opts[:output]) rescue false
  end

end

describe "programmatic interface srf to sqt" do

  srf = Mspire::Sequest::Srf.new(SPEC::Srf_file)

  shared_hash = {
    :lambdas => { 
    basic_conversion: lambda { srf.to_sqt(SPEC::Srf_output) },
    with_new_db_path: lambda { srf.to_sqt(SPEC::Srf_output, :db_info => true, :new_db_path => MS::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33') },
    update_the_db_path: lambda { srf.to_sqt(SPEC::Srf_output, :new_db_path => MS::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33', :update_db_path => true) },
  },
  output: SPEC::Srf_output,
  mkdir: SPEC::TMPDIR,
  original_db_filename: "C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta"
  }

  it_behaves_like "an srf to sqt converter", shared_hash

  before(:each) do
    FileUtils.mkdir(SPEC::TMPDIR) unless File.exist?(SPEC::TMPDIR)
  end
  after(:each) do
    FileUtils.rm_rf(SPEC::TMPDIR)
  end

  # this requires programmatic interface to manipulate the object for this
  # test
  it 'warns if the db path is incorrect and we want to update db info' do
    output = shared_hash[:output]
    # requires some knowledge of how the database file is extracted
    # internally
    wacky_path = '/not/a/real/path/wacky.fasta'

    srf.header.db_filename = wacky_path
    my_error_string = ''
    StringIO.open(my_error_string, 'w') do |strio|
      $stderr = strio
      srf.to_sqt(output, :db_info => true)
    end
    my_error_string.include?(wacky_path).should be_true
    srf.header.db_filename = shared_hash[:original_db_filename]
    $stderr = STDERR
    File.exists?(output).should be_true
    IO.readlines(output).size.should == 80910
    File.delete(output) rescue false
  end
end

describe "command-line interface srf to sqt" do
  before(:each) do
    FileUtils.mkdir(SPEC::TMPDIR) unless File.exist?(SPEC::TMPDIR)
  end
  after(:each) do
    FileUtils.rm_rf(SPEC::TMPDIR)
  end

  def self.commandline_lambda(string)
    lambda { Mspire::Sequest::Srf::Sqt.commandline( string.split(/\s+/) ) }
  end

  base_cmd = "#{SPEC::Srf_file} -o #{SPEC::Srf_output}"
  shared_hash = {
    lambdas: {
    basic_conversion: self.commandline_lambda(base_cmd),
    with_new_db_path: self.commandline_lambda(base_cmd + " --db-info --db-path #{MS::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33'}"),
    update_the_db_path: self.commandline_lambda(base_cmd + " --db-path #{MS::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33'} --db-update" ),
  },
  output: SPEC::Srf_output,
  mkdir: SPEC::TMPDIR,
  }

  it_behaves_like "an srf to sqt converter", shared_hash
end
