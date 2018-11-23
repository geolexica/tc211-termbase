require_relative "terminology_sheet"

module Tc211::Termbase

class InformationSheet < TerminologySheet

  def metadata_section
    sheet_array = @sheet.simple_rows.to_a
    section = MetadataSection.new(sheet_array)
  end

  def to_hash
    { "glossary" => metadata_section.to_hash }
  end

  def to_yaml
    to_hash.to_yaml
  end

end

end