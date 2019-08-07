require_relative "sheet_section"

module Tc211::Termbase

class MetadataSection < SheetSection
  attr_accessor :header_row
  attr_accessor :attributes

  GLOSSARY_HEADER_ROW_MATCH = {
    # "English" uses "".
    # "Arabic" uses "A".
    # This is fixed in the MLGT as of 2018 Aug 6.
    "A" => [nil, "Item", "A"],

    "C" => ["Data Type"],
    "D" => ["Special Instruction"],

    # "Malay" has it empty ("")
    # This is fixed in the MLGT as of 2018 Aug 6.
    "E" => ["ISO 19135 Class.attribute", nil],

    "F" => ["Domain"]
  }

  GLOSSARY_ROW_KEY_MAP = {
    "A" => "name",
    "B" => "value",
    "C" => "datatype",
    "D" => "special-instruction",
    "E" => "19135-class-attribute",
    "F" => "value-domain"
  }

  def initialize(rows, options={})
    super

    self.class.match_header(@rows[0])
    @header_row = @rows[0]
    @body_rows = @rows[1..-1]
    attributes
    self
  end

  def self.match_header(columns)
    # puts "row #{row}"
    columns.each do |key, value|
      # puts "#{key}, #{value}"
      if GLOSSARY_HEADER_ROW_MATCH[key]
        unless GLOSSARY_HEADER_ROW_MATCH[key].include?(value)
          raise RowHeaderMatchError.new("Metadata section header for column `#{key}` does not match expected value `#{value}`")
        end
      end
    end
  end


  def structure
    GLOSSARY_ROW_KEY_MAP
  end

  def parse_row(row)
    return nil if row.empty?
    attribute = {}

    structure.each_pair do |key, value|
      # puts"#{key}, #{value}, #{row[key]}"
      attribute_key = value
      attribute_value = row[key]
      next if attribute_value.nil?
      attribute[attribute_key] = attribute_value
    end

    # TODO: "Chinese" name is empty!
    key = (attribute["name"] || "(empty)").downcase.split(" ").join("-")

    { key => attribute }
  end

  def attributes
    return @attributes if @attributes

    @attributes = {}
    @body_rows.each do |row|
      result = parse_row(row)
      @attributes.merge!(result) if result
    end
    @attributes
  end

  def to_hash
    {
      "metadata" => attributes
    }
  end

end
end
