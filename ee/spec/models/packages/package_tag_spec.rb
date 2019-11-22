# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageTag, type: :model do
  let!(:project) { create(:project) }
  let!(:package) { create(:npm_package, version: '1.0.2', project: project) }

  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    subject { create(:package_tag) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:package_id) }

    context 'with existing package_id and name' do
      let!(:tag) { create(:package_tag) }

      it 'is not valid' do
        invalid = build(:package_tag, package: tag.package, name: tag.name)

        expect(invalid).to be_invalid
        expect(invalid.errors.to_a).to include("Name has already been taken")
      end
    end
  end

  describe '.for_packages' do
    let(:package2) { create(:package, project: project) }
    let(:package3) { create(:package, project: project) }
    let!(:tag1) { create(:package_tag, package: package) }
    let!(:tag2) { create(:package_tag, package: package2) }
    let!(:tag3) { create(:package_tag, package: package3) }

    subject { described_class.for_packages(project.packages) }

    it { is_expected.to match_array([tag1, tag2, tag3]) }
  end
end
