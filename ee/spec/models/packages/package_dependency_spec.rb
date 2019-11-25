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

    context 'with unknown names' do
      let(:names) { %w[unknown test] }

      it { is_expected.to be_empty }
    end

    context 'with different parameters size' do
      let(:names) { %w[foo bar unknown] }

      it 'raises an Argument error' do
        expect { subject }.to raise_error(ArgumentError, "Parameters sizes don't match")
      end
    end

    context 'with parameters size above the chunk size' do
      let!(:package_dependency3) { create(:package_dependency, package: package_dependency1.package, name: "foo3", version_pattern: "~1.5.3") }
      let!(:package_dependency4) { create(:package_dependency, package: package_dependency1.package, name: "foo4", version_pattern: "~1.5.4") }
      let!(:package_dependency5) { create(:package_dependency, package: package_dependency1.package, name: "foo5", version_pattern: "~1.5.5") }
      let!(:package_dependency6) { create(:package_dependency, package: package_dependency1.package, name: "foo6", version_pattern: "~1.5.6") }
      let!(:package_dependency7) { create(:package_dependency, package: package_dependency1.package, name: "foo7", version_pattern: "~1.5.7") }
      let(:names) { %w[foo bar foo3 foo4 foo5 foo6 foo7] }
      let(:version_patterns) { %w[~1.0.0 ~2.5.0 ~1.5.3 ~1.5.4 ~1.5.5 ~1.5.6 ~1.5.7] }

      subject { Packages::PackageDependency.for_names_and_version_patterns(names, version_patterns, 2) }

      it { is_expected.to match_array([package_dependency1, package_dependency2, package_dependency3, package_dependency4, package_dependency5, package_dependency6, package_dependency7]) }
    end
  end
end
