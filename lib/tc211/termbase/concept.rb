module Tc211::Termbase

class Concept < Hash
  attr_accessor :id
  attr_accessor :terms
  DEFAULT_LANGUAGE = "eng"

  def initialize(options={})
    terms = options.delete(:terms) || []
    terms.each do |term|
      add_term(term)
    end

    options.each_pair do |k,v|
      self.send("#{k}=", v)
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

  def default_term
    if self[DEFAULT_LANGUAGE]
      self[DEFAULT_LANGUAGE]
    else
      puts "[tc211-termbase] term (lang: #{keys.first}, ID: #{id}) is missing a corresponding English term, probably needs updating."
      self[keys.first]
    end
  end

  def to_hash
    default_hash = {
      "term" => default_term.term,
      "termid" => id
    }

    self.inject(default_hash) do |acc, (lang, term)|
      acc.merge!(lang => term.to_hash)
    end
  end

  def to_file(filename)
    File.open(filename,"w") do |file|
      file.write(to_hash.to_yaml)
    end
  end

  def to_concept
    concept = Glossarist::ManagedConcept.new(id: id)

    terms.map do |term|
      next if term.nil?

      th = term.to_hash

      th.delete(:term)

      th[:id] = th[:termid]
      th.delete(:termid)

      if as = th.delete(:authoritative_source)
        auth_source = {
          origin: {
            link: as[:link],
            ref: as[:ref],
            clause: as[:clause],
          },
          type: "authority",
          status: "identical"
        }
        th[:sources] << auth_source
      end

      if ls = th.delete(:lineage_source)
        lineage_source = {
          origin: {
            ref: lineage_source,
            link: ls[:link],
            clause: ls[:clause],
          },
          type: "lineage",
          status: lineage_source_similarity
        }
        th[:sources] << lineage_source
      end

      pp th

      localized_concept = Glossarist::LocalizedConcept.new(th)
      # localized_concept.notes << Glossarist::DetailedDefinition.new(universal_entry.value)
      localized_concept.sources = th[:sources]
      concept.add_localization(localized_concept)

    end

    concept
  end

end
end

# term: abbreviation
# termid: 2
# eng:
#   id: 2
#   term: abbreviation
#   definition: designation formed by omitting words or letters from a longer form
#     and designating the same concept
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
#   review_decision_notes: Authoritative reference changed from ISO 1087-1:2000 to
#     ISO 1087-1:2000, 3.4.9. Lineage source added as ISO/TS 19104:2008
#   release: '2'