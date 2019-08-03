require_relative "sheet_section"
require_relative "term"
require_relative "relaton_db"

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
      "Term Abbreviation" => "abbrev",
      # In other sheets, column named "Term_Abbreviation"
      "Term_Abbreviation .OPERATING LANGUAGE." => "abbrev",
      "Country code" => "country-code",
      "Definition" => "definition",
      "Term .OPERATING LANGUAGE - ALTERNATIVE CHARACTER SET." => "alt",
      "Term in English" => nil,
      "Entry Status" => "entry-status",
      ## Must be one of 'notValid' 'valid' 'superseded' 'retired'
      "Term Clasification" => "classification",
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
      @language_code = options.delete(:language_code)
      self
    end

    def structure
      @structure ||= @header_row.inject({}) do |acc, (key, value)|
        # puts "#{key}, #{value}, #{GLOSSARY_HEADER_TITLES[value]}"

        # convert whitespace to a single space
        cleaned_value = value.gsub(/\s+/, ' ')

        matches = TERM_BODY_COLUMN_MAP.map do |key, value|
          # puts "key #{key}, value #{value}"
          if cleaned_value[Regexp.new("^#{key}")]
            [key, value]
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
          src = { "ref" => value }
          ref = value.match(/^[^,\()]+/).to_s.strip.sub(";", ":").
                sub(/\u2011/, "-").sub(/IEC\sIEEE/, "IEC/IEEE")
          item = RelatonDb.instance.fetch ref
          src["link"] = item.url if item
          src
        rescue RelatonBib::RequestError => e
          warn e.message
          src
        end
      else
        value
      end
    end
  end
end
