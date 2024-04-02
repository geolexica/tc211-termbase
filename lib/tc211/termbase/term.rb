module Tc211::Termbase
  class Term
    INPUT_ATTRIBS = %i(
      id
      term
      abbrev
      synonyms
      alt
      definition
      country_code
      language_code
      notes
      examples
      entry_status
      classification
      review_indicator
      authoritative_source
      authoritative_source_similarity
      lineage_source
      lineage_source_similarity
      date_accepted
      date_amended
      review_date
      review_status
      review_type
      review_decision
      review_decision_date
      review_decision_event
      review_decision_notes
      release
    ).freeze

    OUTPUT_ATTRIBS = INPUT_ATTRIBS - %i(term alt abbrev synonyms classification) + %i(terms)

    attr_accessor *(INPUT_ATTRIBS | OUTPUT_ATTRIBS)

    def initialize(options = {})
      @examples = []
      @notes = []
      @definition = []

      # puts "options #{options.inspect}"

      options.each_pair do |k, v|
        v = v.strip if v.is_a?(String)
        next unless v

        case k
        when /^example/
          add_example(v)
        when /^note/
          add_note(v)
        else
          # puts"Key #{k}"
          key = k.gsub("-", "_")
          send("#{key}=", v)
        end
      end
      self
    end

    STRIP_PUNCTUATION = [
      "：",
      ":",
      ".",
      "–",
      "\-",
    ].freeze

    # WARNING
    # Always put the longer Regexp match in front!
    EXAMPLE_PREFIXES = {
      # TODO: fix this, we should not have "EXAMPLES"
      eng: ["EXAMPLES", "EXAMPLE"],
      ara: "مثال",
      chi: "示例",
      dan: "EKSEMPEL",
      dut: ["VOORBEELD", "VOORBEELDEN"],
      fin: "ESIM",
      fre: "Exemple",
      # ger: "",
      jpn: "例",
      kor: "보기",
      pol: "PRZYKŁAD",
      may: "Contoh",
      rus: "Пример",
      spa: "Ejemplo",
      swe: "Exempel",
    }.freeze

    # WARNING
    # Always put the longer Regexp match in front!
    NOTE_PREFIXES = {
      eng: ["Note \\d to entry", "NOTE"],
      ara: "ملاحظة",
      chi: "注",
      dan: "Note",
      dut: "OPMERKING",
      # Matches "HUOM", "HUOM.", "HUOM 1." and "HUOM. 1."
      # (numeral added by the method)
      fin: "HUOM\\.?",
      fre: "A noter",
      # ger: "",
      jpn: "備考",
      kor: "비고",
      pol: "UWAGA",
      may: "catatan",
      rus: "нота",
      spa: "Nota",
      swe: ["Anm. \\d till termpost", "Anm. \\d till terpost", "Anm."],
    }.freeze

    # To match Chinese and Japanese numerals
    ALL_FULL_HALF_WIDTH_NUMBERS = "[0-9０-９]".freeze

    SOURCE_STATUSES = {
      1 => "identical",
      2 => "restyle",
      3 => "context_added",
      4 => "generalisation",
      5 => "specialisation",
      6 => "unspecified",
    }.freeze

    def add_example(example)
      c = clean_prefixed_string(example, EXAMPLE_PREFIXES)
      @examples << c unless c.empty?
    end

    def add_note(note)
      c = clean_prefixed_string(note, NOTE_PREFIXES)
      @notes << c unless c.empty?
    end

    def clean_prefixed_string(string, criterion_map)
      carry = string.to_s.strip
      criterion_map.values.flatten.each do |mat|
        # Arabic notes/examples sometimes use parantheses around numbers
        carry = carry.sub(carry_regex(mat), "")
      end

      carry
    end

    def carry_regex(mat)
      Regexp.new(
        [
          "^#{mat}\s*[#{STRIP_PUNCTUATION.join}]?",
          "\s*\\(?#{ALL_FULL_HALF_WIDTH_NUMBERS}*\\)?\s*",
          "[#{STRIP_PUNCTUATION.join}]?\s*",
        ].join,
      )
    end

    # The termid should ALWAYS be an integer.
    # https://github.com/riboseinc/tc211-termbase/issues/1
    def id=(newid)
      @id = Integer(newid)
    end

    def definition=(definition)
      @definition << definition
    end

    def to_hash
      OUTPUT_ATTRIBS.inject({}) do |acc, attrib|
        value = send(attrib)
        if value.nil?
          acc
        else
          acc.merge(attrib.to_s => value)
        end
      end
    end

    # entry-status
    ## Must be one of notValid valid superseded retired
    def entry_status=(value)
      case value
      when "有效的", "käytössä", "действующий", "válido"
        value = "valid"
      when "korvattu", "reemplazado"
        value = "superseded"
      when "информация отсутствует" # "information absent"!?
        value = "retired"
      when %w(notValid valid superseded retired) # do nothing
      end
      @entry_status = value
    end

    # classification
    ## Must be one of the following: preferred admitted deprecated
    def classification=(value)
      case value
      when "", "认可的", "допустимый", "admitido", "adminitido"
        value = "admitted"
      when "首选的", "suositettava", "suositeltava", "рекомендуемый", "preferente"
        value = "preferred"
      when %w(preferred admitted deprecated)
        # do nothing
      end
      @classification = value
    end

    # review-indicator
    #   Must be one of the following
    #     <empty field>
    #     Under Review in Source Document
    def review_indicator=(value)
      unless ["", "Under Review in Source Document"].include?(value)
        value = ""
      end
      @review_indicator = value
    end

    def authoritative_source=(source)
      clean_source!(source)
      @authoritative_source = source
    end

    # authoritative-source-similarity
    #   Must be one of the following codes:
    #     identical = 1
    #     restyled = 2
    #     context added = 3
    #     generalisation = 4
    #     specialisation = 5
    #     unspecified = 6
    def authoritative_source_similarity=(value)
      unless SOURCE_STATUSES.key?(value)
        value = 6
      end
      @authoritative_source_similarity = value
    end

    def lineage_source=(source)
      clean_source!(source)
      @lineage_source = source
    end

    # lineage-source-similarity
    #   Must be one of the following codes:
    #     identical = 1
    #     restyled = 2
    #     context added = 3
    #     generalisation = 4
    #     specialisation = 5
    #     unspecified = 6
    def lineage_source_similarity=(value)
      unless SOURCE_STATUSES.key?(value)
        value = 6
      end
      @lineage_source_similarity = value
    end

    def clean_source!(source)
      if source.is_a?(Hash)
        source["ref"]&.gsub!(/\(E\),?\s*/, "")
        source["clause"]&.gsub!(/\(E\),?\s*/, "")
      else
        source.gsub!(/\(E\),?\s*/, "")
      end
    end

    ## value Must be one of pending tentative final
    def review_status=(value)
      unless ["", "pending", "tentative", "final"].include?(value)
        value = ""
      end
      @review_status = value
    end

    ## value Must be one of supersession, retirement
    def review_type=(value)
      unless ["", "supersession", "retirement"].include?(value)
        value = ""
      end
      @review_type = value
    end

    ## value Must be one of withdrawn, accepted notAccepted
    def review_decision=(value)
      unless ["", "withdrawn", "accepted", "notAccepted"].include?(value)
        value = ""
      end
      @review_decision = value
    end

    def retired?
      release >= 0
    end

    def terms
      [
        primary_term_hash,
        alt_term_hash,
        abbreviation_term_hash,
        synonyms_term_hash,
      ].compact
    end

    def primary_term_hash
      return unless term

      {
        "type" => "expression",
        "designation" => term,
        "normative_status" => classification,
      }
    end

    def alt_term_hash
      return unless alt

      {
        "type" => "expression",
        "designation" => alt,
        "normative_status" => classification,
      }
    end

    def abbreviation_term_hash
      return unless abbrev

      {
        "type" => "abbreviation",
        "designation" => abbrev,
      }
    end

    def synonyms_term_hash
      return unless synonyms

      {
        "type" => "expression",
        "designation" => synonyms,
      }
    end

    def sources_hash
      [
        authoritative_source_hash,
        lineage_source_hash,
      ].compact
    end

    def authoritative_source_hash
      return unless authoritative_source

      {
        origin: {
          link: authoritative_source["link"],
          ref: authoritative_source["ref"],
          clause: authoritative_source["clause"],
        },
        type: "authoritative",
        status: SOURCE_STATUSES[authoritative_source_similarity],
      }
    end

    def authoritative_source_array
      return unless authoritative_source

      [
        "link" => authoritative_source["link"],
      ]
    end

    def lineage_source_hash
      return unless lineage_source

      {
        origin: {
          ref: lineage_source,
        },
        type: "lineage",
        status: SOURCE_STATUSES[lineage_source_similarity],
      }
    end

    def to_localized_concept_hash
      concept_hash = to_hash

      %w[
        review_status
        review_decision
        review_decision_notes
        review_indicator
        authoritative_source
        authoritative_source_similarity
        lineage_source
        lineage_source_similarity
        country_code
      ].each do |key|
        concept_hash.delete(key)
      end

      concept_hash["id"] = concept_hash["id"].to_s
      concept_hash["sources"] = sources_hash

      if authoritative_source_array
        concept_hash["authoritativeSource"] = authoritative_source_array
      end

      concept_hash
    end
  end
end
