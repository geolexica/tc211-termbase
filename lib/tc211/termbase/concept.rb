module Tc211::Termbase
  class Concept < Hash
    attr_reader :id

    DEFAULT_LANGUAGE = "eng".freeze

    def initialize(options = {})
      super

      terms = options.delete(:terms) || []
      terms.each do |term|
        add_term(term)
      end

      options.each_pair do |k, v|
        send("#{k}=", v)
      end
    end

    # The concept id should ALWAYS be an integer.
    # https://github.com/riboseinc/tc211-termbase/issues/1
    def id=(newid)
      @id = Integer(newid)
    end

    def add_term(term)
      self[term.language_code] = term
    end

    def terms
      values
    end

    def default_term
      if self[DEFAULT_LANGUAGE]
        self[DEFAULT_LANGUAGE]
      else
        puts "[tc211-termbase] term (lang: #{keys.first}, ID: #{id}) is \
          missing a corresponding English term, probably needs updating."
        self[keys.first]
      end
    end

    def to_hash
      default_hash = {
        "term" => default_term.term,
        "termid" => id,
      }

      inject(default_hash) do |acc, (lang, term)|
        acc.merge!(lang => term.to_hash)
      end
    end

    def to_file(filename)
      File.open(filename, "w") do |file|
        file.write(to_hash.to_yaml)
      end
    end

    def to_glossarist_concept
      concept = Glossarist::ManagedConcept.new(data: { id: id.to_s })

      localized_concepts = []

      terms.map do |term|
        next if term.nil?

        localized_concepts << term.to_localized_concept_hash
      end

      concept.localized_concepts = localized_concepts

      concept
    end
  end
end

# term: abbreviation
# termid: 2
# eng:
#   id: 2
#   term: abbreviation
#   definition: designation formed by omitting words or letters from a longer
#     form and designating the same concept
#   language_code: eng
#   notes: []
#   examples: []
#   entry_status: valid
#   classification: preferred
#   authoritative_source:
#     ref: ISO 1087-1:2000
#     clause: 3.4.9
#     link: https://www.iso.org/standard/20057.html
#   lineage_source: ISO/TS 19104:2008
#   lineage_source_similarity: 1
#   date_accepted: 2008-11-15 00:00:00.000000000 +08:00
#   review_date: 2013-01-29 00:00:00.000000000 +08:00
#   review_status: final
#   review_decision: accepted
#   review_decision_date: 2016-10-01 00:00:00.000000000 +08:00
#   review_decision_event: Publication of ISO 19104:2016
#   review_decision_notes: Authoritative reference changed from ISO 1087-1:2000
#     to ISO 1087-1:2000, 3.4.9. Lineage source added as ISO/TS 19104:2008
#   release: '2'
