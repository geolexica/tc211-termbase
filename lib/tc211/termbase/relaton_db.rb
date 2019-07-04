require "singleton"
require "relaton"

module Tc211
  module Termbase
    # Relaton cach singleton.
    class RelatonDb
      include Singleton

      def initialize
        @db = Relaton::Db.new "db", nil
      end

      # @param code [String] reference
      # @return [RelatonIso::IsoBibliongraphicItem]
      def fetch(code)
        @db.fetch code
      end
    end
  end
end
