# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageDependency, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to have_many(:package_dependency_links) }
  end

  describe 'validations' do
    subject { create(:package_dependency) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:version_pattern) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:package_id, :version_pattern) }
  end

  describe '.for_names_and_version_patterns' do
    let!(:package_dependency1) { create(:package_dependency, name: "foo", version_pattern: "~1.0.0") }
    let!(:package_dependency2) { create(:package_dependency, package: package_dependency1.package, name: "bar", version_pattern: "~2.5.0") }
    let(:names) { %w[foo bar] }
    let(:version_patterns) { %w[~1.0.0 ~2.5.0] }

    subject { Packages::PackageDependency.for_names_and_version_patterns(names, version_patterns) }

    it { is_expected.to match_array([package_dependency1, package_dependency2]) }

    context 'with unknown name' do
      let(:names) { %w[unknown test] }

      it { is_expected.to be_empty }
    end

    context 'with different parameters size' do
      let(:names) { %w[foo bar unknown] }

      it 'raises an Argument error' do
        expect { subject }.to raise_error(ArgumentError, "Parameters sizes don't match")
      end
    end
  end
end
