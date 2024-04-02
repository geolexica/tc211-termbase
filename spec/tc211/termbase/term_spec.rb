RSpec.describe Tc211::Termbase::Term do
  describe ".authoritative_source=" do
    context "when contains '(E)'" do
      let(:authoritative_source) do
        {
          "ref" => "ISO/TS 19159-4:2022",
          "clause" => "(E), 3.22",
          "link" => "http://foobar.com",
        }
      end

      let(:expected_authoritative_source) do
        {
          "ref" => "ISO/TS 19159-4:2022",
          "clause" => "3.22",
          "link" => "http://foobar.com",
        }
      end

      it "expect to remove '(E)' from source" do
        expect { subject.authoritative_source = authoritative_source }
          .to change { subject.authoritative_source }
          .from(nil)
          .to(expected_authoritative_source)
      end
    end
  end
end
