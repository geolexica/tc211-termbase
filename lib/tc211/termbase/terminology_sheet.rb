require_relative "metadata_section"
require_relative "terms_section"
require "iso-639"

module Tc211::Termbase

class TerminologySheet
  attr_accessor :sheet

  def initialize(sheet)
    @sheet = sheet
    self
  end

  def language
    @sheet.name
  end

  def language_code
    # Hack to make ISO_639 gem work...
    lang = case language
    when "Dutch"
      "Dutch; Flemish"
    when "Spanish"
      "Spanish; Castilian"
    else
      language
    end
    ISO_639.find_by_english_name(lang).alpha3
  rescue
    raise StandardError.new("Failed to find alpha3 code for language: #{lang}")
  end

  def sections_raw
    # Sections either start with "A" => "Item", or they have empty lines between
    raw_sections = @sheet.simple_rows.to_a

    raw_sections.reject! do |section|
      section.empty?
    end

    raw_sections = raw_sections.slice_before do |row|
      row["A"].to_s == "Item" || row["A"].to_s.match(/^ISO 19135 Field/)
    end.to_a
  end

  def terms_section
    sections

    sections.detect do |section|
      section.is_a?(TermsSection)
    end
  end

  def sections
    return @sections if @sections

    @sections = []
    sections_raw.each_with_index do |x,i|
      # puts "rows: #{x.inspect}"

      section = nil
      %w(MetadataSection TermsSection).each do |t|
        break if section
        begin
          # puts "rows: #{x.inspect}"
          section = ::Tc211::Termbase.const_get(t).new(x, {language_code: language_code})
        rescue SheetSection::RowHeaderMatchError
        end
      end

      unless section
        raise SheetSection::UnknownHeaderError.new("Unable to find header row match for section #{i} header, contents: #{x.inspect}")
      end

      puts "--------- Section #{i} is a #{section.class.name} ---------"

      @sections << section
    end

  end

end

end