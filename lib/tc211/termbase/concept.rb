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

end
end