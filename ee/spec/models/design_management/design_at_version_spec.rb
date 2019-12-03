# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::DesignAtVersion do
  include DesignManagementTestHelpers

  set(:issue) { create(:issue) }
  set(:issue_b) { create(:issue) }

  describe '#id' do
    let(:design) { create(:design, issue: issue) }
    let(:version) { create(:design_version, designs: [design], issue: issue) }
    subject { described_class.new(design: design, version: version) }

    it 'combines design.id and version.id' do
      expect(subject.id).to include(design.id.to_s, version.id.to_s)
    end
  end

  describe 'validations' do
    subject(:design_at_version) { build(:design_at_version) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:design) }
    it { is_expected.to validate_presence_of(:version) }
  end

  describe 'factory' do
    subject(:design_at_version) { create(:design_at_version) }

    it { is_expected.to be_valid }
    it { is_expected.to be_persisted }
  end

  def id_of(design, version)
    described_class.new(design: design, version: version).id
  end

  describe '.lazy_find' do
    let!(:version_a) do
      create(:design_version, issue: issue,
                              designs: create_list(:design, 3, issue: issue))
    end

    let(:id_a) { id_of(version_a.designs.first,  version_a) }
    let(:id_b) { id_of(version_a.designs.second, version_a) }
    let(:id_c) { id_of(version_a.designs.last,   version_a) }

    it 'issues at most one query' do
      expect do
        dav_a = described_class.lazy_find(id_a)
        dav_b = described_class.lazy_find(id_b)
        dav_c = described_class.lazy_find(id_c)

        expect(dav_a.version).to eq(version_a)
        expect(dav_b.version).to eq(version_a)
        expect(dav_c.version).to eq(version_a)

        expect(version_a.designs).to include(dav_a.design, dav_b.design, dav_c.design)
      end.not_to exceed_query_limit(1)
    end
  end

  describe '.find_all' do
    # 2 versions, with 5 total designs on issue A, so 2*5 = 10
    let!(:version_a) do
      create(:design_version, issue: issue,
                              designs: create_list(:design, 3, issue: issue))
    end
    let!(:version_b) do
      create(:design_version, issue: issue,
                              designs: create_list(:design, 2, issue: issue))
    end
    # 1 version, with 3 designs on issue B, so 1*3 = 3
    let!(:version_c) do
      create(:design_version, issue: issue_b,
                              designs: create_list(:design, 3, issue: issue_b))
    end

    describe '#count' do
      it 'counts 13 records' do
        expect(described_class.find_all.count).to eq(13)
      end

      it 'issues at most one query' do
        expect { described_class.find_all.count }.not_to exceed_query_limit(1)
      end
    end

    describe 'to_a' do
      it 'finds 13 records' do
        expect(described_class.find_all.to_a).to have_attributes(size: 13)
      end

      it 'finds DesignAtVersion records' do
        expect(described_class.find_all.to_a).to all(be_a(described_class))
      end

      it 'issues at most one query' do
        expect { described_class.find_all.to_a }.not_to exceed_query_limit(1)
      end
    end

    describe '#for_ids' do
      let(:query) { described_class.find_all.for_ids(ids) }

      context 'invalid ids' do
        let(:ids) do
          version_b.designs.map { |d| id_of(d, version_c) }
        end

        describe '#count' do
          it 'counts 0 records' do
            expect(query.count).to eq(0)
          end
        end

        describe '#empty?' do
          it 'is empty' do
            expect(query).to be_empty
          end
        end

        describe '#to_a' do
          it 'finds no records' do
            expect(query.to_a).to eq([])
          end
        end
      end

      context 'valid ids' do
        let(:ids) do
          version_b.designs.map { |d| id_of(d, version_a) }
        end

        describe '#count' do
          it 'counts 2 records' do
            expect(query.count).to eq(2)
          end

          it 'issues at most one query' do
            expect { query.count }.not_to exceed_query_limit(1)
          end
        end

        describe '#to_a' do
          it 'finds 2 records' do
            expect(query.to_a).to contain_exactly(described_class, described_class)
          end

          it 'only returns records with matching IDs' do
            expect(query.map(&:id).to_set).to eq(ids.to_set)
          end

          it 'issues at most one query' do
            expect { query.to_a }.not_to exceed_query_limit(1)
          end
        end
      end
    end
  end
end
