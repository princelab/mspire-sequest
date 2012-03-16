require 'spec_helper'

require 'mspire/sequest/params'
require 'mspire/sequest/pepxml/modifications'

describe 'Mspire::Sequest::Pepxml::Modifications' do
  before do
    tf_params = TESTFILES + "/bioworks32.params"
    @params = Mspire::Sequest::Params.new(tf_params)
    # The params object here is completely unnecessary for this test, except
    # that it sets up the mass table
    @obj = Mspire::Sequest::Pepxml::Modifications.new(@params, "(M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000) ")
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
    mod = Mspire::Sequest::Pepxml::Modifications.new(@params, mod_string)
    ## no mods
    peptide_nomod = "PEPTIDE"
    ok mod.modification_info(peptide_nomod).nil?
    peptide_mod = "]M*EC^S@IDM#M*EMSCM["
    modinfo = mod.modification_info(peptide_mod)

    xml_string = modinfo.to_xml
    xml_string.matches /<mod_aminoacid_mass /
    xml_string.matches /mod_nterm_mass=/
    xml_string.matches /mod_cterm_mass=/
    xml_string.matches /modified_peptide=/

    modinfo.mod_aminoacid_masses.size.is 5
    mod_aa_masses = modinfo.mod_aminoacid_masses
    # positions are verified, masses are just frozen
    [1,3,4,7,8].zip([147.09606, 115.1429, 167.0772999, 160.19606, 147.09606], mod_aa_masses) do |pos, mass, obj|
      obj.position.is pos
      obj.mass.should.be.close mass, 0.0001
    end
    # These values are just frozen and not independently verified yet
    modinfo.mod_nterm_mass.should.be.close 146.4033, 0.0001
    modinfo.mod_cterm_mass.should.be.close 160.5334, 0.0001
  end

end

