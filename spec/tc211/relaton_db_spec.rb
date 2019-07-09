RSpec.describe Tc211::Termbase::RelatonDb do
  it "fetchs correction" do
    doc = Tc211::Termbase::RelatonDb.instance.fetch "ISO 19110:2005/Amd 1:2011"
    expect(doc).to_not be_nil
  end
end
