# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageDependencyLink, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to belong_to(:package_dependency) }
  end

  describe 'validations' do
    subject { create(:package_dependency_link) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:package_dependency) }

    context 'package_id + package_dependency_id uniqueness for dependency_type' do
      it 'is not valid' do
        exisiting_link = subject
        link = build(
          :package_dependency_link,
          package: exisiting_link.package,
          package_dependency: exisiting_link.package_dependency,
          dependency_type: exisiting_link.dependency_type
        )

        expect(link).not_to be_valid
        expect(link.errors.to_a).to include("Dependency type has already been taken")
      end
    end
  end

  describe '.with_dependency_type' do
    let!(:link1) { create(:package_dependency_link) }
    let!(:link2) { create(:package_dependency_link, package: link1.package, package_dependency: link1.package_dependency, dependency_type: :devDependencies) }
    let!(:link3) { create(:package_dependency_link, package: link1.package, package_dependency: link1.package_dependency, dependency_type: :bundleDependencies) }

    subject { described_class }

    it 'returns links of the given type' do
      expect(subject.with_dependency_type(:bundleDependencies)).to eq([link3])
    end
  end
end
