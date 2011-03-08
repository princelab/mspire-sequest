
module Ms ; end
module Ms::Sequest ; end

class Ms::Sequest::Params

  # returns a Ms::Ident::Pepxml::SampleEnzyme object
  def sample_enzyme
    Ms::Ident::Pepxml::SampleEnzyme.new(sample_enzyme_hash)
  end

  # returns a hash suitable for setting a Ms::Ident::Pepxml::SampleEnzyme object
  def sample_enzyme_hash
    (offset, cleave_at, except_if_after) = enzyme_specificity.map do |v|
      if v == '' ; nil ; else v end
    end
    hash = {}
    hash[:name] = self.enzyme
    hash[:cut] = cleave_at
    hash[:no_cut] = except_if_after
    hash[:sense] =
      if hash[:name] == "No_Enzyme"
        nil
      elsif offset == 1
        'C'
      elsif offset == 0
        'N'
      end
    hash
  end

end
