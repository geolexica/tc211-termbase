module Tc211::Termbase

class Term

  ATTRIBS = %i(
    id term abbrev synonyms alt definition
    country_code
    language_code
    notes examples
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
  )

  attr_accessor *ATTRIBS

  def initialize(options={})
    @examples = []
    @notes = []

    # puts "options #{options.inspect}"

    options.each_pair do |k, v|
      v = v.strip if v.is_a?(String)
      next unless v
      case k
      when /^example/
        @examples << v
      when /^note/
        @notes << v
      else
        # puts"Key #{k}"
        key = k.gsub("-", "_")
        self.send("#{key}=", v)
      end
    end
    self
  end

  def to_hash
    ATTRIBS.inject({}) do |acc, attrib|
      value = self.send(attrib)
      unless value.nil?
        acc.merge(attrib.to_s => value)
      else
        acc
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
    when %w(notValid valid superseded retired)
      # do nothing
    end
    @entry_status = value
  end

  # classification
  ## Must be one of the following: preferred admitted deprecated
  def classification=(value)
    case value
    when ""
      value = "admitted"
    when "认可的", "допустимый", "admitido"
      value = "admitted"
    when "首选的", "suositettava", "suositeltava", "рекомендуемый", "preferente"
      value = "preferred"
    when %w(preferred admitted deprecated)
      # do nothing
    end
    @classification = value
  end

  # review-indicator
  ## Must be one of the following <empty field> Under Review in Source Document",
  def review_indicator=(value)
    unless ["", "Under Review in Source Document"].include?(value)
      value = ""
    end
    @review_indicator = value
  end

  # authoritative-source-similarity
  #     ## Must be one of the following codes: identical = 1 restyled = 2 context added = 3 generalisation = 4 specialisation = 5 unspecified = 6",
  def authoritative_source_similarity=(value)
    unless (1..6).include?(value)
      value = 6
    end
    @authoritative_source_similarity = value
  end

  # lineage-source-similarity
  #     ## Must be one of the following codes: identical = 1 restyled = 2 context added = 3 generalisation = 4 specialisation = 5 unspecified = 6",
  def authoritative_source_similarity=(value)
    unless (1..6).include?(value)
      value = 6
    end
    @authoritative_source_similarity
  end

  def review_status=(value) ## Must be one of pending tentative final
    unless ["", "pending", "tentative", "final"].include?(value)
      value = ""
    end
    @review_status = value
  end

  def review_type=(value)     ## Must be one of supersession, retirement
    unless ["", "supersession", "retirement"].include?(value)
      value = ""
    end
    @review_type = value
  end

  def review_decision=(value) ## Must be one of withdrawn, accepted notAccepted
    unless ["", "withdrawn", "accepted", "notAccepted"].include?(value)
      value = ""
    end
    @review_decision = value
  end

  def retired?
    release >= 0
  end

end

end