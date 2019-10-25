RSpec.describe Tc211::Termbase do
  it "has a version number" do
    expect(Tc211::Termbase::VERSION).not_to be nil
  end

  it "runs the command without an error" do
    FileUtils.rm_rf "concepts" if File.exist? "concepts"
    FileUtils.rm "termbase.yaml" if File.exist? "termbase.yaml"
    expect { `exe/tc211-termbase-xlsx2yaml spec/fixtures/termbase.xlsx` }.
      to_not output.to_stderr
  end
end
