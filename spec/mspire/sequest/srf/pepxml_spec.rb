require 'spec_helper'

require 'mspire/sequest/srf/pepxml'

describe 'an Mspire::Ident::Pepxml object from an srf file with modifications' do
  before do
    FileUtils.mkdir @out_path unless File.exist?(@out_path)
  end
  after do
    FileUtils.rm_rf @out_path
  end

  @srf_file = SEQUEST_DIR + '/opd1_2runs_2mods/sequest331/020.srf'
  @out_path = TESTFILES + '/tmp'
  @srf = Mspire::Sequest::Srf.new(@srf_file)

  it 'produces xml with all the expected parts' do
    tags = %w(msms_pipeline_analysis msms_run_summary sample_enzyme specificity search_summary search_database enzymatic_search_constraint aminoacid_modification parameter spectrum_query search_result search_hit modification_info mod_aminoacid_mass search_score)
    pepxml = @srf.to_pepxml(:verbose => false)
    xml_string = pepxml.to_xml
    tags.each do |tag|
      xml_string.matches %r{<#{tag}}
    end
  end

  # takes an xml string of attributes (' key="val" key2="val2" ') and a xml
  # node that is expected to have those attributes
  def has_attributes(node, string)
    if node.nil?
      raise "your xml node is nil!!!"
    end
    if node == []
      raise "you gave me an empty array instead of a node"
    end
    # strips the tail end quote mark, also
    string.strip!
    string.chomp!('"')
    string.split(/"\s+/).each do |str|
      (key,val) = str.split('=',2)
      val=val[1..-1] if val[0,1] == '"' 
      if node[key] != val
        puts "FAILING"
        puts "EXPECT: #{key} => #{val} ACTUAL => #{val}"
        puts "NODE KEYS: "
        p node.keys
        puts "NODE VALUES: "
        p node.values
      end
      node[key].is val
    end
  end

  it 'gets everything right' do
    xml_string = @srf.to_pepxml(:verbose => false).to_xml
    doc = Nokogiri::XML.parse(xml_string, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS)

    root = doc.root

    root.name.is "msms_pipeline_analysis"
    has_attributes( root, 'schemaLocation="http://regis-web.systemsbiology.net/pepXML /tools/bin/TPP/tpp/schema/pepXML_v115.xsd"' )
    root['date'].nil?.is false
    root['summary_xml'].matches "020.xml"
    root.namespaces.is( {"xmlns" => "http://regis-web.systemsbiology.net/pepXML" } )

    mrs_node = root.child
    mrs_node.name.is 'msms_run_summary'
    has_attributes( mrs_node, 'msManufacturer="Thermo" msModel="LCQ Deca XP" msIonization="ESI" msMassAnalyzer="Ion Trap" msDetector="UNKNOWN" raw_data=".mzML"' )
    se_node = mrs_node.child
    se_node.name.is 'sample_enzyme'
    has_attributes se_node, 'name="Trypsin"'
    specificity_node = se_node.child
    specificity_node.name.is 'specificity'
    has_attributes specificity_node, 'cut="KR" no_cut="P" sense="C"'
    search_summary_node = se_node.next_sibling
    search_summary_node.name.is 'search_summary'
    has_attributes search_summary_node, 'search_engine="SEQUEST" precursor_mass_type="average" fragment_mass_type="average" search_id="1"'
    search_summary_node['base_name'].matches %r{sequest/opd1_2runs_2mods/sequest331/020$}
    # TODO: expand the search summary check!
    # TODO: finish testing other guys for accurcy
  
  end
end


