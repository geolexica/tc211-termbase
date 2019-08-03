
module Tc211::Termbase

class SheetSection

  class RowHeaderMatchError < StandardError; end
  class UnknownHeaderError < StandardError; end

  attr_accessor :sheet_content

  def initialize(rows, options={})
    # rows is an array of rows!
    raise unless rows.is_a?(Array)
    @rows = rows
    # @has_header = options[:has_header].nil? ? true : options[:has_header]
    self
  end

  # Abstract method
  def self.match_header(row)
    false
  end

  def self.identify_type(row)

  end

  # TODO
end
end