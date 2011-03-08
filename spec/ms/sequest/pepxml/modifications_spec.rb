require 'spec_helper'

require 'ms/sequest/params'
require 'ms/sequest/pepxml/modifications'

describe 'Ms::Sequest::Pepxml::Modifications' do
  before do
    tf_params = TESTFILES + "/bioworks32.params"
    @params = Ms::Sequest::Params.new(tf_params)
    # The params object here is completely unnecessary for this test, except
    # that it sets up the mass table
    @obj = Ms::Sequest::Pepxml::Modifications.new(@params, "(M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000) ")
  end
  it 'creates a mod_symbols_hash' do
    answ = {[:C, 12.0]=>"^", [:S, 80.0]=>"@", [:M, 29.0]=>"#", [:M, 15.9]=>"*", [:ct, 12.33]=>"[", [:nt, 14.2]=>"]"}
    @obj.mod_symbols_hash.should == answ
    ## need more here
  end

  it 'creates a ModificationInfo object given a special peptide sequence' do
    mod_string = "(M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000) "
    @params.diff_search_options = "15.90000 M 29.00000 M 80.00000 S 12.00000 C"
    @params.term_diff_search_options = "14.20000 12.33000"
    mod = Ms::Sequest::Pepxml::Modifications.new(@params, mod_string)
    ## no mods
    peptide = "PEPTIDE"
    ok mod.modification_info(peptide).nil?
    peptide = "]M*EC^S@IDM#M*EMSCM["
    modinfo = mod.modification_info(peptide)
    modinfo.modified_peptide.should == peptide
    p modinfo
    p modinfo.mod_aminoacid_masses
    puts modinfo.to_xml
    # the positions should be present and correct  for the
    # mod_aminoacid_masses !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    fail
    # These guys were probably using average ??
    #modinfo.mod_nterm_mass.should.be.close 146.40054, 0.000001
    #modinfo.mod_cterm_mass.should.be.close 160.52994, 0.000001
    # These values are just frozen and not independently verified yet
    modinfo.mod_nterm_mass.should.be.close 146.4033, 0.0001
    modinfo.mod_cterm_mass.should.be.close 160.5334, 0.0001
  end

end

