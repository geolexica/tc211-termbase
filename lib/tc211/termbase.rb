require "glossarist"
require "tc211/termbase/version"

require_relative "termbase/glossarist/concept"
require_relative "termbase/glossarist/managed_concept"

module Tc211
  module Termbase
    class Error < StandardError; end

    # Your code goes here...
    ::Glossarist.configure do |config|
      config.register_extension_attributes(["authoritativeSource"])

      config.register_class(:localized_concept, Tc211::Termbase::Glossarist::Concept)
      config.register_class(:managed_concept, Tc211::Termbase::Glossarist::ManagedConcept)
    end
  end
end

require 'tc211/termbase/term_workbook'
require 'tc211/termbase/concept_collection'
