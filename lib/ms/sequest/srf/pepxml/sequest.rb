module Ms ; end
module Ms::Ident ; end

class Ms::Ident::Pepxml 
  class SearchHit
    Sequest = Struct.new(:xcorr, :deltacn, :deltacnstar, :spscore, :sprank) do

      # Takes ions in the form XX/YY and returns [XX.to_i, YY.to_i]
      def self.split_ions(ions)
        ions.split("/").map {|ion| ion.to_i }
      end

      def to_xml(builder)
        members.zip(self.to_a) do |sym, val|
          builder.search_score(:name => sym, :value => val)
        end
      end
    end
  end
end

