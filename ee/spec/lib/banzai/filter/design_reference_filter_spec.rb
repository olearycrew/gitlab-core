# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::DesignReferenceFilter do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  # Persistent stuff we only want to create once
  let_it_be(:project)  { create(:project, :public) }
  let_it_be(:issue)    { create(:issue, project: project) }
  let_it_be(:issue_b)  { create(:issue, project: project) }
  let_it_be(:design_a) { create(:design, issue: issue) }
  let_it_be(:design_b) { create(:design, issue: issue_b) }

  let_it_be(:project2)         { create(:project, :public) }
  let_it_be(:issue2)           { create(:issue, project: project2) }
  let_it_be(:x_project_design) { create(:design, issue: issue2) }

  # Transitory stuff we can compute cheaply from other things
  let(:design) { design_a }
  let(:reference) { design.to_reference }
  let(:input_text) { "Added #{reference}" }
  let(:doc) { reference_filter(input_text) }

  def process(text)
    reference_filter(text).to_html
  end

  def parse(ref)
    described_class.object_class.reference_pattern.match(ref)
  end

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      text = "<#{elem}>Design #{design.to_reference}</#{elem}>"

      expect(process(text)).to eq(text)
    end
  end

  describe 'parsing' do
    where(:filename) do
      [
        ['simple.png'],
        ['SIMPLE.PNG'],
        ['has spaces.png'],
        ['has-hyphen.jpg'],
        ['snake_case.svg'],
        ['has ] right bracket.gif'],
        [%q{has slashes \o/.png}],
        [%q{has "quote" 'marks'.gif}],
        [%q{<a href="has">html elements</a>.gif}]
      ]
    end

    with_them do
      where(:fullness) do
        [
          [true],
          [false]
        ]
      end

      with_them do
        let(:design) { build(:design, issue: issue, filename: filename) }
        let(:reference) { design.to_reference(full: fullness) }
        let(:parsed) do
          m = parse(reference)
          described_class.parse_symbol(m[described_class.object_sym], m) if m
        end

        it 'can parse the reference' do
          expect(parsed).to include(
            filename: filename,
            issue_iid: issue.iid
          )
        end
      end
    end
  end

  context 'a design with a quoted filename' do
    let(:filename) { %q{A "very" good file.png} }
    let(:design) { create(:design, issue: issue, filename: filename) }

    it 'links to the design' do
      expect(doc.css('a').first.attr('href'))
        .to eq url_for_design(design)
    end
  end

  context 'internal reference' do
    it_behaves_like 'a reference containing an element node'

    context "the reference is valid" do
      it 'links to the design' do
        expect(doc.css('a').first.attr('href'))
          .to eq url_for_design(design)
      end

      it 'includes a title attribute' do
        expect(doc.css('a').first.attr('title')).to eq(design.filename)
      end

      it 'includes default classes' do
        expect(doc.css('a').first.attr('class')).to eq('gfm gfm-design has-tooltip')
      end

      it 'includes a data-project attribute' do
        link = doc.css('a').first

        expect(link).to have_attribute('data-project')
        expect(link.attr('data-project')).to eq project.id.to_s
      end

      it 'includes a data-issue attribute' do
        doc = reference_filter("See #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-issue')
        expect(link.attr('data-issue')).to eq issue.id.to_s
      end

      it 'includes a data-original attribute' do
        link = doc.css('a').first

        expect(link).to have_attribute('data-original')
        expect(link.attr('data-original')).to eq reference
      end

      context 'the filename needs to be escaped' do
        let(:xss) do
          <<~END
            <script type="application/javascript">
              alert('xss')
            </script>
          END
        end

        let(:filename) { %Q{#{xss}.png} }
        let(:design) { create(:design, filename: filename, issue: issue) }

        it 'leaves the text as is' do
          expect(doc.text).to eq(input_text)
        end

        it 'escapes the title' do
          expect(doc.css('a').first.attr('title')).to eq(design.filename)
        end
      end
    end

    context "the reference is to a non-existant design" do
      let(:reference) { build(:design).to_reference }

      it 'ignores it' do
        expect(process(reference)).to eq(reference)
      end
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:reference) { x_project_design.to_reference(project) }

    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq url_for_design(x_project_design)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.full_path}##{issue.iid}[#{x_project_design.filename}]")
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-design has-tooltip'
    end

    it 'ignores invalid designs on the referenced project' do
      invalid_ref = "Fixed #{reference.gsub(/jpg/, 'gif')}"

      expect(process(invalid_ref)).to eq(invalid_ref)
    end
  end

  describe 'performance' do
    it 'does not have a N+1 query problem' do
      single_reference = "Design #{design_a.to_reference}"
      multiple_references = <<~MD
      Designs:
       * #{design_a.to_reference}
       * #{design_b.to_reference}
       * #{x_project_design.to_reference(project)}
       * #1[not a valid reference.gif]
      MD

      expect { process(multiple_references) }.to issue_same_number_of_queries_as { process(single_reference) }
    end
  end
end
