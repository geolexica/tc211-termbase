module Tc211::Termbase

class Concept < Hash
  attr_accessor :id
  attr_accessor :terms

  def initialize(options={})
    terms = options.delete(:terms) || []
    terms.each do |term|
      add_term(term)
    end

    options.each_pair do |k,v|
      self.send("#{k}=", v)
    end
  end

  def add_term(term)
    self[term.language_code] = term
  end

  def to_hash
    self.inject({}) do |acc, (lang, term)|
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