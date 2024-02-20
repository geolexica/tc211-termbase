require_relative "sheet_section"

module Tc211::Termbase
  class MetadataSection < SheetSection
    attr_accessor :header_row
    attr_writer :attributes

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

      "F" => ["Domain"],
    }.freeze

    GLOSSARY_ROW_KEY_MAP = {
      "A" => "name",
      "B" => "value",
      "C" => "datatype",
      "D" => "special-instruction",
      "E" => "19135-class-attribute",
      "F" => "value-domain",
    }.freeze

    def initialize(rows, options = {})
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
        header_row_match = GLOSSARY_HEADER_ROW_MATCH[key]
        if header_row_match && !header_row_match.include?(value)
          raise RowHeaderMatchError.new(
            "Metadata section header for column `#{key}` does not match \
            expected value `#{value}`",
          )
        end
      end
    end

    def structure
      GLOSSARY_ROW_KEY_MAP
    end

    def clean_key(key)
      key.strip
        .downcase
        .gsub(/[()]/, "")
        .gsub(" ", "-")
    end

    def clean_value(value)
      return nil if value.nil?

      case value
      when String
        value.strip
      else
        value
      end
    end

    def parse_row(row)
      return nil if row.empty?

      attribute = {}

      structure.each_pair do |key, value|
        attribute_value = clean_value(row[key])
        next if attribute_value.nil?

        attribute[clean_key(value)] = attribute_value
      end

      # TODO: "Chinese" name is empty!
      key = clean_key(attribute["name"] || "(empty)")

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

    def fields
      # "operating-language-country"=>
      #  {"name"=>"Operating Language Country",
      #   "value"=>"410",
      #   "datatype"=>"Country Code",
      #   "special-instruction"=>
      #    "ftp.ics.uci.edu/pub/ietf/http/related/iso3166.txt",
      #   "19135-class-attribute"=>"RE_Register.operatingLanguage",
      #   "value-domain"=>
      #    "<<Data Type>>RE_Locale.country \n" +
      #    "[ISO 3166-1 3-character numeric country code]"},
      #

      attributes.inject({}) do |acc, (k, v)|
        acc.merge({ k => v["value"] })
      end
    end

    def to_hash
      {
        "metadata" => fields,
      }
    end
  end
end
