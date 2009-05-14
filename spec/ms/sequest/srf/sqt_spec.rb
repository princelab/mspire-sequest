require File.expand_path( File.dirname(__FILE__) + '/../../../tap_spec_helper' )

require 'ms/sequest/srf'

SpecHelperHeaderHash = {
  'SQTGenerator' => 'mspire',
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
  'StaticMod' => ['C=160.1901','Cterm=10.1230','E=161.4455'],
  'DynamicMod' => ['STY*=+79.97990', 'M#=+14.02660'],
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

# 'converting a large srf to sqt'
class SRF_TO_SQT < MiniTest::Spec
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

  spec_large do
    before(:all) do
      @file = Tfiles_l + '/opd1_static_diff_mods/000.srf'
      @output = Tfiles_l + '/opd1_static_diff_mods/000.sqt.tmp'
      @srf = SRF.new(@file)
      @original_db_filename = @srf.header.db_filename
    end
    it 'converts without bothering with the database' do
      @srf.to_sqt(@output)
      @output.exist_as_a_file?.should be_true
      lines = File.readlines(@output)
      lines.size.must_equal 80910
      header_lines = lines.grep(/^H/)
      (header_lines.size > 10).should be_true
      header_hash_match(header_lines, SpecHelperHeaderHash).should be_true
      other_lines = lines.grep(/^[^H]/)
      other_lines[0,4].join('').must_equal SpecHelperOtherLines
      other_lines[-3,3].join('').must_equal SpecHelperOtherLinesEnd
      del(@output)
    end
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
      my_error_string.should include(wacky_path)
      @srf.header.db_filename = @original_db_filename
      $stderr = STDERR
      @output.exist_as_a_file?.should be_true
      IO.readlines(@output).size.must_equal 80910
      del(@output)
    end
    it 'can get db info with correct path' do
      @srf.to_sqt(@output, :db_info => true, :new_db_path => Tfiles_l + '/opd1_2runs_2mods/sequest33')
      @output.exist_as_a_file?.should be_true
      lines = IO.readlines(@output)
      has_md5 = lines.any? do |line|
        line =~ /DBMD5Sum\s+202b1d95e91f2da30191174a7f13a04e/
      end
      has_md5.should be_true

      has_seq_len = lines.any? do |line|
        # frozen
        line =~ /DBSeqLength\s+1342842/
      end
      has_seq_len.should be_true
      lines.size.must_equal 80912
      del(@output)
    end
    it 'can update the Database' do
      @srf.to_sqt(@output, :new_db_path => Tfiles_l + '/opd1_2runs_2mods/sequest33', :update_db_path => true)
      regexp = Regexp.new("Database\t/.*/opd1_2runs_2mods/sequest33/ecoli_K12_ncbi_20060321.fasta")
      updated_db = IO.readlines(@output).any? do |line|
        line =~ regexp
      end
      updated_db.should be_true
      del(@output)
    end
  end
end
