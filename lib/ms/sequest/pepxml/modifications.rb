require 'ms/ident/pepxml/search_hit/modification_info'

module Ms ; end
module Ms::Sequest ; end
class Ms::Sequest::Pepxml ; end

class Ms::Sequest::Pepxml::Modifications
  # sequest params object
  attr_accessor :params
  # array holding AAModifications 
  attr_accessor :aa_mods
  # array holding TerminalModifications
  attr_accessor :term_mods
  # a hash of all differential modifications present by aa_one_letter_symbol
  # and special_symbol. This is NOT the mass difference but the total mass {
  # 'M*' => 155.5, 'S@' => 190.3 }.  NOTE: Since the termini are dependent on
  # the amino acid sequence, they are give the *differential* mass.  The
  # termini are given the special symbol as in sequest e.g. '[' => 12.22, #
  # cterminus    ']' => 14.55 # nterminus
  attr_accessor :masses_by_diff_mod_hash
  # a hash, key is [AA_one_letter_symbol.to_sym, difference.to_f]
  # values are the special_symbols
  attr_accessor :mod_symbols_hash

  # returns an array of all modifications (aa_mods, then term_mods)
  def modifications
    aa_mods + term_mods
  end

  # The modification symbols string looks like this:
  # (M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000)
  # ct is cterminal peptide (differential)
  # nt is nterminal peptide (differential)
  # the C is just cysteine
  # will set_modifications and masses_by_diff_mod hash
  def initialize(params=nil, modification_symbols_string='')
    @params = params
    if @params
      set_modifications(params, modification_symbols_string)
    end
  end

  # set the masses_by_diff_mod and mod_symbols_hash from 
  def set_hashes(modification_symbols_string)

    @mod_symbols_hash = {}
    @masses_by_diff_mod = {}
    if (modification_symbols_string == nil || modification_symbols_string == '')
      return nil
    end
    table = @params.mass_index(:precursor)
    modification_symbols_string.split(/\)\s+\(/).each do |mod|
      if mod =~ /\(?(\w+)(.) (.[\d\.]+)\)?/
        if $1 == 'ct' || $1 == 'nt' 
          mass_diff = $3.to_f
          @masses_by_diff_mod[$2] = mass_diff
          @mod_symbols_hash[[$1.to_sym, mass_diff]] = $2.dup
          # changed from below to match tests, is this right?
          # @mod_symbols_hash[[$1, mass_diff]] = $2.dup
        else
          symbol_string = $2.dup 
          mass_diff = $3.to_f
          $1.split('').each do |aa|
            aa_as_sym = aa.to_sym
            @masses_by_diff_mod[aa+symbol_string] = mass_diff + table[aa_as_sym]
            @mod_symbols_hash[[aa_as_sym, mass_diff]] = symbol_string
          end
        end
      end
    end
  end
  # returns an array of static mod objects and static terminal mod objects
  def create_static_mods(params)

    ####################################
    ## static mods
    ####################################

    static_mods = [] # [[one_letter_amino_acid.to_sym, add_amount.to_f], ...]
    static_terminal_mods = [] # e.g. [add_Cterm_peptide, amount.to_f]

    params.mods.each do |k,v|
      v_to_f = v.to_f
      if v_to_f != 0.0
        if k =~ /add_(\w)_/
          static_mods << [$1.to_sym, v_to_f]
        else
          static_terminal_mods << [k, v_to_f]
        end
      end
    end
    aa_hash = params.mass_index(:precursor)

    ## Create the static_mods objects
    static_mods.map! do |mod|
      hash = {
        :aminoacid => mod[0].to_s,
        :massdiff => mod[1],
        :mass => aa_hash[mod[0]] + mod[1],
        :variable => 'N',
        :binary => 'Y',
      } 
      Ms::Ident::Pepxml::AminoacidModification.new(hash)
    end

    ## Create the static_terminal_mods objects
    static_terminal_mods.map! do |mod|
      terminus = if mod[0] =~ /Cterm/ ; 'c'
                 else                 ; 'n' # only two possible termini
                 end
      protein_terminus = case mod[0] 
                         when /Nterm_protein/ ; 'n'
                         when /Cterm_protein/ ; 'c'
                         else nil
                         end

      # create the hash                            
      hash = {
        :terminus => terminus,
        :massdiff => mod[1],
        :variable => 'N',
        :description => mod[0],
      }
      hash[:protein_terminus] = protein_terminus if protein_terminus
      Ms::Ident::Pepxml::TerminalModification.new(hash)
    end
    [static_mods, static_terminal_mods]
  end

  # 1. sets aa_mods and term_mods from a sequest params object
  # 2. sets @params
  # 3. sets @masses_by_diff_mod
  def set_modifications(params, modification_symbols_string)
    @params = params

    set_hashes(modification_symbols_string)
    (static_mods, static_terminal_mods) = create_static_mods(params)

    aa_hash = params.mass_index(:precursor)
    #################################
    # Variable Mods:
    #################################
    arr = params.diff_search_options.rstrip.split(/\s+/)
    # [aa.to_sym, diff.to_f]
    variable_mods = []
    (0...arr.size).step(2) do |i|
      if arr[i].to_f != 0.0
        variable_mods << [arr[i+1], arr[i].to_f]
      end
    end
    mod_objects = []
    variable_mods.each do |mod|
      mod[0].split('').each do |aa|
        hash = {

          :aminoacid => aa,
          :massdiff => mod[1],
          :mass => aa_hash[aa.to_sym] + mod[1],
          :variable => 'Y',
          :binary => 'N',
          :symbol => @mod_symbols_hash[[aa.to_sym, mod[1]]],
        }
        mod_objects << Ms::Ident::Pepxml::AminoacidModification.new(hash)
      end
    end

    variable_mods = mod_objects
    #################################
    # TERMINAL Variable Mods:
    #################################
    # These are always peptide, not protein termini (for sequest)
    (nterm_diff, cterm_diff) = params.term_diff_search_options.rstrip.split(/\s+/).map{|v| v.to_f }

    to_add = []
    if nterm_diff != 0.0
      to_add << ['n',nterm_diff.to_plus_minus_string, @mod_symbols_hash[:nt, nterm_diff]]
    end
    if cterm_diff != 0.0
      to_add << ['c', cterm_diff.to_plus_minus_string, @mod_symbols_hash[:ct, cterm_diff]]
    end

    variable_terminal_mods = to_add.map do |term, mssdiff, symb|
      hash = {
        :terminus => term,
        :massdiff => mssdiff,
        :variable => 'Y',
        :symbol => symb,
      }
      Ms::Ident::Pepxml::TerminalModification.new(hash)
    end

    #########################
    # COLLECT THEM
    #########################
    @aa_mods = static_mods + variable_mods
    @term_mods = static_terminal_mods + variable_terminal_mods
  end

  # takes a peptide sequence with modifications but no preceding or trailing
  # amino acids.  (e.g. expects "]PEPT*IDE" but not 'K.PEPTIDE.R')
  # returns a ModificationInfo object 
  #  if there are no modifications, returns nil
  def modification_info(peptide)
    if @masses_by_diff_mod.size == 0
      return nil
    end
    hash = {}
    hash[:modified_peptide] = peptide.dup
    hsh = @masses_by_diff_mod  
    table = @params.mass_index(:precursor)
    h_plus = table['h+']  # this? or h_plus ??
    oh = table['oh']
    ## only the termini can match a single char
    if hsh.key? peptide[0,1]
      # AA + H + differential_mod
      hash[:mod_nterm_mass] = table[peptide[1,1].to_sym] + h_plus + hsh[peptide[0,1]]
      peptide = peptide[1...(peptide.size)]
    end
    if hsh.key? peptide[(peptide.size-1),1]
      # AA + OH + differential_mod
      hash[:mod_cterm_mass] = table[peptide[(peptide.size-2),1].to_sym] + oh + hsh[peptide[-1,1]]
      peptide.slice!( 0..-2 )
      peptide = peptide[0...(peptide.size-1)]
    end
    mod_array = []
    (0...peptide.size).each do |i|
      if hsh.key? peptide[i,2]
        mod_array << Ms::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new([ i+1 , hsh[peptide[i,2]] ])
      end
    end
    if mod_array.size > 0
      hash[:mod_aminoacid_masses] = mod_array
    end
    if hash.size > 1  # if there is more than just the modified peptide there
      Ms::Ident::Pepxml::SearchHit::ModificationInfo.new(hash)
      #Sequest::Pepxml::SearchHit::ModificationInfo.new(hash.values_at(:modified_peptide, :mod_aminoacid_masses, :mod_nterm_mass, :mod_cterm_mass)
    else
      nil
    end
  end


end

