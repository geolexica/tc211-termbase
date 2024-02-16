RSpec.describe Tc211::Termbase do
  it "has a version number" do
    expect(Tc211::Termbase::VERSION).not_to be nil
  end

  it "runs the command without an error" do
    FileUtils.rm_rf "concepts" if File.exist? "concepts"
    FileUtils.rm "termbase.yaml" if File.exist? "termbase.yaml"

    expect { `ruby exe/tc211-termbase-xlsx2yaml spec/fixtures/termbase.xlsx` }
      .to_not output.to_stderr
  end

  describe "validate generated concept files" do
    before(:all) do
      unless File.exist?("concepts")
        `ruby exe/tc211-termbase-xlsx2yaml spec/fixtures/termbase.xlsx`
      end
    end

    context "concept count" do
      let(:concepts_count) { Dir.glob("concepts/concept/*").count }

      it "should to be 18" do
        expect(concepts_count).to eq(18)
      end
    end

    context "localized_concept count" do
      let(:localized_concepts_count) { Dir.glob("concepts/localized_concept/*").count }

      it "should to be 193" do
        expect(localized_concepts_count).to eq(193)
      end
    end

    context "collection count" do
      let(:collection) do
        coll = Glossarist::ManagedConceptCollection.new
        coll.load_from_files("concepts")
        coll
      end

      it "should to be 18" do
        expect(collection.count).to eq(18)
      end
    end
  end

  describe "validate generated concept by glossarist" do
    it "should be readable by glossarist" do
      collection = Glossarist::ManagedConceptCollection.new

      expect { collection.load_from_files("concepts") }
        .to_not output.to_stderr
    end

    context "collection" do
      let(:collection) do
        coll = Glossarist::ManagedConceptCollection.new
        coll.load_from_files("concepts")
        coll
      end

      it "should contain 18 concepts" do
        expect(collection.count).to be(18)
      end

      it "should contain 193 localized concepts" do
        expect(collection.sum { |c| c.localizations.count }).to be(193)
      end

      context "concept 2" do
        let(:concept) { collection.fetch("2") }

        it "should have 7 localized concepts" do
          expect(concept.localized_concepts.count).to be(7)
        end

        context "eng localization" do
          let(:localized_concept) { concept.localization("eng") }

          let(:expected_hash) do
            {
              "data" => {
                "dates" => [
                  {
                    "date" => Time.parse("2008-11-15 00:00:00 +0500"),
                    "type" => "accepted",
                  },
                ],
                "definition" => [
                  {
                    "content" => "designation formed by omitting words or letters from a longer form and designating the same concept"
                  },
                ],
                "examples" => [],
                "id" => "2",
                "notes" => [],
                "release" => "2",
                "sources" => [
                  {
                    "origin" => {
                      "ref" => "ISO 1087-1:2000",
                      "clause" => "3.4.9",
                      "link" => "https://www.iso.org/standard/20057.html"
                    },
                    "type" => "authoritative",
                    "status" => "identical",
                  },
                  {
                    "origin" => {
                      "ref" => "ISO/TS 19104:2008"
                    },
                    "type" => "lineage",
                    "status" => "identical",
                  },
                ],
                "terms" => [
                  {
                    "type" => "expression",
                    "normative_status" => "preferred",
                    "designation" => "abbreviation",
                  },
                ],
                "language_code" => "eng",
                "entry_status" => "valid",
                "review_date" => Time.parse("2013-01-29 00:00:00 +0500"),
                "review_decision_date" => Time.parse("2016-10-01 00:00:00 +0500"),
                "review_decision_event" => "Publication of ISO 19104:2016"
              }
            }
          end

          it "should have all the fields" do
            expect(localized_concept.to_h).to eq(expected_hash)
          end
        end
      end
    end
  end
end
