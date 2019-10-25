require_relative "sheet_section"
require_relative "term"
require_relative "relaton_db"
require "relaton_bib"

module Tc211::Termbase

  class TermsSection < SheetSection
    attr_accessor :structure
    attr_accessor :header_row

    TERM_HEADER_ROW_MATCH = {
      "A" => ["ISO 19135 Field\nRE_RegisterItem.itemIdentifier"],
      "B" => ["ISO 19135 Field\nRE_RegisterItem.name"],
      "C" => ["ISO 19135 Field\nRE_RegisterItem.\nalternativeExpression"],
      "D" => ["Country_Code"],
      # ... We don't need to match all the cells
    }

    TERM_BODY_COLUMN_MAP = {
      "Term_ID" => "id",
      "Term" => "term",
      "Term .OPERATING LANGUAGE." => "term",
      # In the English sheet, column is named "Term Abbreviation"
      # This is fixed in the MLGT as of 2018 Aug 6.
      "Term Abbreviation" => "abbrev",
      "Term_Abbreviation" => "abbrev",
      # In other sheets, column named "Term_Abbreviation"
      "Term_Abbreviation .OPERATING LANGUAGE." => "abbrev",

      "Country code" => "country-code",
      "Definition" => "definition",
      "Term .OPERATING LANGUAGE - ALTERNATIVE CHARACTER SET." => "alt",
      "Term in English" => nil,
      "Entry Status" => "entry-status",
      ## Must be one of 'notValid' 'valid' 'superseded' 'retired'

      # "Term Clasification" is misspelt.
      # This is fixed in the MLGT as of 2018 Aug 6.
      "Term Clasification" => "classification",
      "Term Classification" => "classification",

      ## Must be one of the following 'preferred' 'admitted' 'deprecated'
      "Review Indicator" => "review-indicator",
      ## Must be one of the following <empty field> 'Under Review in Source Document'",
      "Authoritative Source" => "authoritative-source",
      "Similarity to Authoritative Source" => "authoritative-source-similarity",
      ## Must be one of the following codes: 'identical' = 1 'restyled' = 2 'context added' = 3 'generalisation' = 4 'specialisation' = 5 'unspecified' = 6",
      "Lineage Source" => "lineage-source",
      "Similarity to Lineage Source" => "lineage-source-similarity",
      ## Must be one of the following codes: 'identical' = 1 'restyled' = 2 'context added' = 3 'generalisation' = 4 'specialisation' = 5 'unspecified' = 6",
      "Term Synonyms" => "synonyms",
      "Date Accepted" => "date-accepted", # yyyy-mm-dd,
      "Date Amended" => "date-amended",   # yyyy-mm-dd,
      "Review Date" => "review-date",     # yyyy-mm-dd,
      "Review Status" => "review-status", ## Must be one of 'pending' 'tentative' 'final'",
      "Review Type" => "review-type",     ## Must be one of 'supersession', 'retirement'",
      "Review Decision" => "review-decision", ## Must be one of 'withdrawn', 'accepted' 'notAccepted'",
      "Review Decision Date" => "review-decision-date", # yyyy-mm-dd
      "Review Decision Event" => "review-decision-event",
      "Review Decision Notes" => "review-decision-notes",
      "Example_1" => "example-1",
      "Note_1" => "note-1",
      "Example_2" => "example-2",
      "Note_2" => "note-2",
      "Example_3" => "example-3",
      "Note_3" => "note-3",
      "Example_4" => "example-4",
      "Note_4" => "note-4",
      "Example_5" => "example-5",
      "Note_5" => "note-5",
      "Example_6" => "example-6",
      "Note_6" => "note-6",
      "Example_7" => "example-7",
      "Note_7" => "note-7",
      "Example_8" => "example-8",
      "Note_8" => "note-8",
      "Glossary Release" => "release"
      ## Must be one of the following codes 'release1' = 1 'release1_retired' = -1 'release2' = 2 'release2_retired' = -2 etc "
    }

    def initialize(rows, options={})
      super
      self.class.match_header(@rows[0])
      @mapping_rows = @rows[0..1]
      @header_row = @rows[2]
      @body_rows = @rows[3..-1]
      @language_code = options.delete(:parent_sheet).language_code
      self
    end

    def structure
      return @structure if @structure

      header_mapping = parse_header_mapping
      validate_header_mapping(header_mapping)

      @structure = header_mapping
    end

    def parse_header_mapping
      @header_row.inject({}) do |acc, (key, value)|
        # puts "#{key}, #{value}, #{GLOSSARY_HEADER_TITLES[value]}"

        # convert whitespace to a single space
        cleaned_value = value.gsub(/\s+/, ' ')
        # puts "cleaned_value #{cleaned_value}"

        matches = TERM_BODY_COLUMN_MAP.map do |key, value|
          if match = cleaned_value[Regexp.new("^#{key}")]
            # puts "matched! key #{key}, value #{value}, match (#{match}, #{match.length})"
            [key, value]
          else
            # puts "no match! key #{key}, value #{value}"
            nil
          end
        end.compact

        discard, longest_match_key = matches.max_by do |(a, b)|
          a.length
        end

        # Here we need to skip "Term in English"
        if key && longest_match_key
          acc.merge!({ key => longest_match_key })
        else
          acc
        end

      end
    end

    class HeaderMappingInvalidError < StandardError; end;

    # Validate structure
    # - should not have multiple columns mapping to the same key
    def validate_header_mapping(header_mapping)
      header_mapping.group_by do |k, v|
        v
      end.each do |k, v|
        if v.length > 1
          raise HeaderMappingInvalidError.new("Data key '#{k}' mapping from columns #{v.map(&:first)}; it should only be mapped from one column. Please check the TERM_BODY_COLUMN_MAP constant.")
        end
      end
    end

    def self.match_header(columns)
      # puts "row #{row}"
      columns.each do |key, value|
        # puts "#{key}, #{value}"
        if TERM_HEADER_ROW_MATCH[key]
          unless TERM_HEADER_ROW_MATCH[key].include?(value)
            raise RowHeaderMatchError.new("Terminology section header for column `#{key}` does not match expected value `#{value}`")
          end
        end
      end

      # row.inject(true) do |acc, (key, value)|
      #   if TERM_HEADER_ROW_MATCH[key]
      #     acc && TERM_HEADER_ROW_MATCH[key].include?(value)
      #
      #   else
      #     acc
      #   end
      # end
    end

    def parse_row(row)
      return nil if row.empty?

      attributes = {}

      structure.each_pair do |key, value|
        # puts "#{key}, #{value}, #{row[key]}"
        attribute_key = value
        next if row[key].nil?

        attribute_value = fetch_attribute row[key], attribute_key
        attributes[attribute_key] = attribute_value
      end

      attributes
    end

    def terms
      @terms ||= @body_rows.map do |row|
        Term.new(parse_row(row).merge("language_code" => @language_code))
      end
    end

    def to_hash
      {
        "terms" => terms.map(&:to_hash)
      }
    end

    private

    # @param value [String]
    # @param key [String]
    # @return [Hash]
    def fetch_attribute(value, key)
      case key
      when "authoritative-source"
        begin
          raw_ref = value.match(/\A[^,\()]+/).to_s

          clean_ref = raw_ref.
            sub(";", ":").
            sub(/\u2011/, "-").
            sub(/IEC\sIEEE/, "IEC/IEEE")

          clause = value.
            gsub(raw_ref, "").
            gsub(/\A,?\s+/,"")

          item = ::Tc211::Termbase::RelatonDb.instance.fetch clean_ref

          src = {}
          src["ref"] = clean_ref
          src["clause"] = clause unless clause.empty?
          src["link"] = item.url if item
          src
        rescue ::RelatonBib::RequestError => e
          warn e.message
          src
        end
      else
        value
      end
    end
  end
end
