

HeaderHash = {}
header_doublets = [
  %w(SQTGenerator	mspire),
  %w(SQTGeneratorVersion	0.3.1),
  %w(Database	C:\Xcalibur\database\ecoli_K12_ncbi_20060321.fasta),
  %w(FragmentMasses	AVG),
  %w(PrecursorMasses	AVG),
  ['StartTime', ''],
  ['Alg-MSModel', 'LCQ Deca XP'],
  %w(DBLocusCount	4237),
  %w(Alg-FragMassTol	1.0000),
  %w(Alg-PreMassTol	25.0000),
  ['Alg-IonSeries', '0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0'],
  %w(Alg-PreMassUnits	ppm),
  ['Alg-Enzyme', 'Trypsin(KR/P) (2)'],

  ['Comment', ['ultra small file created for testing', 'Created from Bioworks .srf file']],
  ['DynamicMod', ['M*=+15.99940', 'STY#=+79.97990']],
  ['StaticMod', []],
].each do |double|
  HeaderHash[double[0]] = double[1]
end

TestSpectra = {
  :first => { :first_scan=>2, :last_scan=>2, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>390.92919921875, :total_intensity=>2653.90307617188, :lowest_sp=>0.0, :num_matched_peptides=>0, :matches=>[]},
  :last => { :first_scan=>27, :last_scan=>27, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>393.008056640625, :total_intensity=>2896.16967773438, :lowest_sp=>0.0, :num_matched_peptides=>0, :matches=>[] },
  :seventeenth => {:first_scan=>23, :last_scan=>23, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>1022.10571289062, :total_intensity=>3637.86059570312, :lowest_sp=>0.0, :num_matched_peptides=>41},
  :first_match_17 => { :rxcorr=>1, :rsp=>5, :mh=>1022.11662242, :deltacn_orig=>0.0, :xcorr=>0.725152492523193, :sp=>73.9527359008789, :ions_matched=>6, :ions_total=>24, :sequence=>"-.MGT#TTM*GVK.L", :manual_validation_status=>"U", :first_scan=>23, :last_scan=>23, :charge=>1, :deltacn=>0.0672458708286285, :aaseq => 'MGTTTMGVK' },
  :last_match_17 => {:rxcorr=>10, :rsp=>16, :mh=>1022.09807242, :deltacn_orig=>0.398330867290497, :xcorr=>0.436301857233047, :sp=>49.735767364502, :ions_matched=>5, :ions_total=>21, :sequence=>"-.MRT#TSFAK.V", :manual_validation_status=>"U", :first_scan=>23, :last_scan=>23, :charge=>1, :deltacn=>1.1, :aaseq => 'MRTTSFAK'},
  :last_match_17_last_loci => {:reference =>'gi|16129390|ref|NP_415948.1|', :first_entry =>'gi|16129390|ref|NP_415948.1|', :locus =>'gi|16129390|ref|NP_415948.1|', :description => 'Fake description' }
}

