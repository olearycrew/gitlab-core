# frozen_string_literal: true
require 'spec_helper'

describe Packages::CreateDependencyService do
  describe '#execute' do
    let(:namespace) {create(:namespace)}
    let(:project) { create(:project, namespace: namespace) }
    let(:user) { create(:user) }
    let(:version) { '1.0.1'.freeze }
    let(:package_name) { "@#{namespace.path}/my-app".freeze }

    context 'when packages are published' do
      let(:json_file) { 'npm/payload.json' }
      let(:params) do
        JSON.parse(fixture_file(json_file, dir: 'ee')
                .gsub('@root/npm-test', package_name)
                .gsub('1.0.1', version))
                .with_indifferent_access
      end
      let(:package_version) { params[:versions].keys.first }
      let(:dependencies) { params[:versions][package_version] }
      let!(:package) { create(:npm_package) }
      let(:dependency_names) { package.dependencies.map(&:name).sort }
      let(:dependency_link_types) { package.dependency_links.map(&:dependency_type).sort }

      subject { described_class.new(package, dependencies).execute }

      it 'creates dependencies and links' do
        expect { subject }
          .to change { Packages::Dependency.count }.by(1)
          .and change { Packages::DependencyLink.count }.by(1)
        expect(dependency_names).to match_array(%w(express))
        expect(dependency_link_types).to match_array(%w(dependencies))
      end

      context 'with repeated packages' do
        let(:json_file) { 'npm/payload_with_duplicated_packages.json' }

        it 'creates dependencies and links' do
          expect { subject }
            .to change { Packages::Dependency.count }.by(4)
            .and change { Packages::DependencyLink.count }.by(7)
          expect(dependency_names).to match_array(%w(express dagre-d3 d3 d3))
          expect(dependency_link_types).to match_array(%w(bundleDependencies dependencies dependencies deprecated devDependencies devDependencies peerDependencies))
        end
      end
    end
  end
end
