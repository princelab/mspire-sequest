require File.expand_path( File.dirname(__FILE__) + '/../../../spec_helper' )

require 'ms/sequest/srf'
require 'ms/sequest/srf/sqt'

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

Srf_file = Ms::TESTDATA + '/sequest/opd1_static_diff_mods/000.srf' 
Srf_output = Ms::TESTDATA + '/sequest/opd1_static_diff_mods/000.sqt.tmp'

shared 'an srf to sqt converter' do

  before do
    @original_db_filename = "C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta"
    @output = Srf_output
  end

  def del(file)
    if File.exist?(file)
      File.unlink(file)
    end
  end

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

  it 'converts without bothering with the database' do
    @basic_conversion.call
    ok File.exist?(@output)
    lines = File.readlines(@output)
    lines.size.is 80910
    header_lines = lines.grep(/^H/)
    ok(header_lines.size > 10)
    ok header_hash_match(header_lines, SpecHelperHeaderHash)
    other_lines = lines.grep(/^[^H]/)
    other_lines[0,4].join('').is SpecHelperOtherLines
    other_lines[-3,3].join('').is SpecHelperOtherLinesEnd
    del(@output)
  end


  it 'can get db info with correct path' do
    @with_new_db_path.call
    ok File.exist?(@output)
    lines = IO.readlines(@output)
    has_md5 = lines.any? do |line|
      line =~ /DBMD5Sum\s+202b1d95e91f2da30191174a7f13a04e/
    end
    ok has_md5

    has_seq_len = lines.any? do |line|
      # frozen
      line =~ /DBSeqLength\s+1342842/
    end
    ok has_seq_len
    lines.size.is 80912
    del(@output)
  end

  it 'can update the Database' do
    @update_the_db_path.call
    regexp = Regexp.new("Database\t/.*/opd1_2runs_2mods/sequest33/ecoli_K12_ncbi_20060321.fasta")
    updated_db = IO.readlines(@output).any? do |line|
      line =~ regexp
    end
    ok updated_db
    del(@output)
  end

end

describe "programmatic interface srf to sqt" do

  @srf = Ms::Sequest::Srf.new(Srf_file)

  @basic_conversion = lambda { @srf.to_sqt(Srf_output) }
  @with_new_db_path = lambda { @srf.to_sqt(Srf_output, :db_info => true, :new_db_path => Ms::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33') }
  @update_the_db_path = lambda { @srf.to_sqt(Srf_output, :new_db_path => Ms::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33', :update_db_path => true) }

  before do
    @output = Srf_output
  end

  behaves_like "an srf to sqt converter"

  # this requires programmatic interface to manipulate the object for this
  # test
  it 'warns if the db path is incorrect and we want to update db info' do
    # requires some knowledge of how the database file is extracted
    # internally
    wacky_path = '/not/a/real/path/wacky.fasta'
    @srf.header.db_filename = wacky_path
    my_error_string = ''
    StringIO.open(my_error_string, 'w') do |strio|
      $stderr = strio
      @srf.to_sqt(@output, :db_info => true)
    end
    ok my_error_string.include?(wacky_path)
    @srf.header.db_filename = @original_db_filename
    $stderr = STDERR
    ok File.exists?(@output)
    IO.readlines(@output).size.is 80910
    del(@output)
  end
end

describe "command-line interface srf to sqt" do
  def commandline_lambda(string)
    lambda { Ms::Sequest::Srf::Sqt.commandline( string.split(/\s+/) ) }
  end

  base_cmd = "#{Srf_file} -o #{Srf_output}"
  @basic_conversion = commandline_lambda(base_cmd)
  @with_new_db_path = commandline_lambda(base_cmd + " --db-info --db-path #{Ms::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33'}")
  @update_the_db_path = commandline_lambda(base_cmd + " --db-path #{Ms::TESTDATA + '/sequest/opd1_2runs_2mods/sequest33'} --db-update" )

  behaves_like "an srf to sqt converter"
end
