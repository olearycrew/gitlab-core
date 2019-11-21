# frozen_string_literal: true
require 'spec_helper'

describe Packages::CreateNpmPackageService do
  let(:namespace) {create(:namespace)}
  let(:project) { create(:project, namespace: namespace) }
  let(:user) { create(:user) }
  let(:version) { '1.0.1'.freeze }

  let(:params) do
    JSON.parse(
      fixture_file('npm/payload.json', dir: 'ee')
        .gsub('@root/npm-test', package_name)
        .gsub('1.0.1', version))
        .with_indifferent_access
  end

  subject { described_class.new(project, user, params).execute }

  shared_examples 'valid package' do
    it 'creates a package' do
      expect { subject }
        .to change { Packages::Package.count }.by(1)
        .and change { Packages::Package.npm.count }.by(1)
    end

    it { is_expected.to be_valid }

    it 'creates a package with name and version' do
      package = subject

      expect(package.name).to eq(package_name)
      expect(package.version).to eq(version)
    end
  end

  describe '#execute' do
    context 'scoped package' do
      let(:package_name) { "@#{namespace.path}/my-app".freeze }

      it_behaves_like 'valid package'
    end

    context 'invalid package name' do
      let(:package_name) { "@#{namespace.path}/my-group/my-app".freeze }

      it 'raises a RecordInvalid error' do
        service = described_class.new(project, user, params)

        expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'package already exists' do
      let(:package_name) { "@#{namespace.path}/my_package" }

      it 'returns a validation error' do
        create(:npm_package, project: project, name: package_name, version: '1.0.1')

        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with incorrect namespace' do
      let(:package_name) { '@my_other_namespace/my-app' }

      it 'raises a RecordInvalid error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
