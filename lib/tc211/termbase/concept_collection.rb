require_relative "concept"

module Tc211::Termbase
  class ConceptCollection < Hash
    def add_term(term)
      if self[term.id]
        self[term.id].add_term(term)
      else
        self[term.id] = Concept.new(
          id: term.id,
          terms: [term],
        )
      end
    end

    def to_hash
      inject({}) do |acc, (id, concept)|
        acc.merge!(id => concept.to_hash)
      end
    end

    def to_file(filename)
      File.open(filename, "w") do |file|
        file.write(to_hash.to_yaml)
      end
    end

    def to_concept_collection
      collection = ::Glossarist::ManagedConceptCollection.new

      values.each do |term_concept|
        next if term_concept.nil?

        collection.store(term_concept.to_glossarist_concept)
      end

      collection
    end
  end
end
