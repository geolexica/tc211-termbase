RSpec.describe Tc211::Termbase::TermWorkbook do
  subject { Tc211::Termbase::TermWorkbook.new("spec/fixtures/termbase.xlsx") }

  it "returns authoritative source" do
    term = subject.language_sheet("English").terms_section.terms.first
    thash = term.to_hash
    expect(thash["authoritative_source"]["ref"]).to eq "ISO 1087-1:2000"
    expect(thash["authoritative_source"]["clause"]).to eq "3.4.9"
    expect(thash["authoritative_source"]["link"]).to eq "https://www.iso.org/standard/20057.html"
  end

  # TODO: test against these patterns:
  # patterns = [
  #   "ISO 1087-1:2000, 3.4.15",
  #   "ISO/TS 19130:2010",
  #   "ISO/IEC Guide 99:2007, 2.15",
  #   "ISO/IEC 10746-2",
  #   "ISO/IEC 19501:2005 (Adapted from)",
  #   "ISO 19108;2002",
  #   "ISO/IEC TR 10000-1:1998",
  #   "ISO 10241-1:2011, 3.4.2.3, modified — The reference to the examples has been removed.",
  #   "ISO 19103:2015, modified – Derived from 7.5.2.1",
  #   "ISO/TS 19159-2:2016, 4.1",
  #   "ISO 19146:2010, 4.9, modified — In the definition, the words terminological record have been changed to terminological entry.",
  #   "ISO 19111:2007, 4.22, modified – The first occurrence of the words “semi-major” have been expanded to “semi-major axis”.",
  #   "ISO 19111:2007, 4.22, modificado – la primera ocurrencia de las palabras \"semi-mayor\" se han ampliado a \"semieje mayor\"",
  #   "ISO/IEC 11179-3:2003(Adapted from)",
  #   "ISO 2859‑5:2005, 3.4, modified – Original Example has been removed. Note 1 to entry has been added."
  # ]

end
