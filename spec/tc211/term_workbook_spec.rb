RSpec.describe Tc211::Termbase::TermWorkbook do
  subject { Tc211::Termbase::TermWorkbook.new("spec/fixtures/termbase.xlsx") }

  it "returns authoritative source" do
    term = subject.language_sheet("English").terms_section.terms.first
    thash = term.to_hash
    expect(thash["authoritative_source"]["ref"]).to eq "ISO 1087-1:2000, 3.4.9"
    expect(thash["authoritative_source"]["link"]).to eq "https://www.iso.org/standard/20057.html"
  end
end
