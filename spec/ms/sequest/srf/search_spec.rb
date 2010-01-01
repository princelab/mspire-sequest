require File.expand_path( File.dirname(__FILE__) + '/../../../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/search_spec_helper' )

require 'fileutils'

require 'ms/sequest/srf'
require 'ms/sequest/srf/search'

describe 'converting a large srf to an ms search format' do

  @file = Ms::TESTDATA + '/sequest/opd1_static_diff_mods/000.srf'
  @srf = Ms::Sequest::Srf.new(@file)

  def del(file)
    if File.exist?(file)
      if File.directory?(file)
        FileUtils.rm_rf(file)
      else
        File.unlink(file)
      end
    end
  end

  it 'converts to mgf' do
    @output = Ms::TESTDATA + '/sequest/opd1_static_diff_mods/000.mgf.tmp'
    @srf.to_mgf(@output)
    ok File.exist?(@output)
    output = IO.read(@output)
    # tests are just frozen right now, not checked for accuracy
    ok output.include?(SRF_TO_MGF_HELPER::FIRST_MSMS)
    ok output[1000..-1].include?(SRF_TO_MGF_HELPER::LAST_MSMS)
    del(@output)
  end

  it 'generates .dta files' do
    @output = Ms::TESTDATA + '/sequest/opd1_static_diff_mods/000.dta.tmp'
    @srf.to_dta(@output)
    ok File.exist?(@output)
    ok File.directory?(@output)
    # frozen (not verified):
    Dir[@output + "/*.*"].size.is 3893 # the correct number files

    first_file = @output + '/000.2.2.1.dta'
    ok File.exist?(first_file) 
    IO.read(first_file).is SRF_TO_DTA_HELPER::FIRST_SCAN.gsub("\n", "\r\n")
    last_file = @output + '/000.3748.3748.3.dta'
    IO.read(last_file).is SRF_TO_DTA_HELPER::LAST_SCAN.gsub("\n", "\r\n")

    del(@output)
  end

end

