require_relative "metadata_section"
require_relative "terms_section"

module Tc211::Termbase

class TerminologySheet
  attr_accessor :sheet, :language_code

  def initialize(sheet)
    @sheet = sheet
    self
  end

  def language
    @sheet.name
  end

  def language_code
    return @language_code unless @language_code.nil?
    raise StandardError.new("Language code not parsed yet for sheet: #{language}")
  end

  # Read language_code from sheet
  def set_language_code(code)
    # puts "language_code is #{code}"
    return @language_code unless @language_code.nil?

    @language_code = case code
    when "dut/nld"
      "dut"
    when "工作语言代码"
      "chn"
    else
      code
    end
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

  def metadata_section
    sections

    sections.detect do |section|
      section.is_a?(MetadataSection)
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
          section = ::Tc211::Termbase.const_get(t).new(x, {parent_sheet: self})
        rescue SheetSection::RowHeaderMatchError
        end
      end

      unless section
        raise SheetSection::UnknownHeaderError.new("Unable to find header row match for section #{i} header, contents: #{x.inspect}")
      end

      # MetadataSections always go first, so the language_code must already
      # be set at the time of parsing the TermsSection
      if section.is_a?(MetadataSection)
        code = section.fields["operating-language-code"]
        # puts "lang code is detected as #{code}, #{@language_code}"
        unless code.nil?
          # puts "setting lang code is detected as #{code}"
          set_language_code(code)
        end
      end

      puts "--------- Section #{i} is a #{section.class.name} ---------"

      @sections << section
    end

  end

end

end