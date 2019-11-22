# frozen_string_literal: true
require 'spec_helper'

describe API::NpmPackages do
  let(:group)   { create(:group) }
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:token)   { create(:oauth_access_token, scopes: 'api', resource_owner: user) }

  before do
    project.add_developer(user)
    stub_licensed_features(packages: true)
  end

  shared_examples 'a package that requires auth' do
    it 'returns the package info with oauth token' do
      get_package_with_token(package)

      expect_a_valid_package_response
    end

    it 'denies request without oauth token' do
      get_package(package)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /api/v4/packages/npm/*package_name' do
    let(:package) { create(:npm_package, project: project) }

    context 'a public project' do
      it 'returns the package info without oauth token' do
        get_package(package)

        expect_a_valid_package_response
      end

      context 'project path with a dot' do
        let(:project) { create(:project, :public, namespace: group, path: 'foo.bar') }

        it 'returns the package info' do
          get_package(package)

          expect_a_valid_package_response
        end
      end
    end

    context 'internal project' do
      before do
        project.team.truncate
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package that requires auth'
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package that requires auth'

      it 'denies request when not enough permissions' do
        project.add_guest(user)

        get_package_with_token(package)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      get_package(package)

      expect(response).to have_gitlab_http_status(403)
    end

    def get_package(package, params = {})
      get api("/packages/npm/#{package.name}"), params: params
    end

    def get_package_with_token(package, params = {})
      get_package(package, params.merge(access_token: token.token))
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let(:package) { create(:npm_package, project: project) }
    let(:package_file) { package.package_files.first }

    context 'a public project' do
      it 'returns the file' do
        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns the file' do
        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'denies download when no private token' do
        get_file(package_file)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      get_file(package_file)

      expect(response).to have_gitlab_http_status(403)
    end

    def get_file(package_file, params = {})
      get api("/projects/#{project.id}/packages/npm/" \
              "#{package_file.package.name}/-/#{package_file.file_name}"), params: params
    end

    def get_file_with_token(package_file, params = {})
      get_file(package_file, params.merge(access_token: token.token))
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    context 'when params are correct' do
      context 'invalid package record' do
        context 'unscoped package' do
          let(:package_name) { 'my_unscoped_package' }
          let(:params) { upload_params(package_name) }

          it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
            expect { upload_package_with_token(package_name, params) }
              .not_to change { project.packages.count }

            expect(response).to have_gitlab_http_status(400)
          end

          context 'with empty versions' do
            let(:params) { upload_params(package_name).merge!(versions: {}) }

            it 'throws a 400 error' do
              expect { upload_package_with_token(package_name, params) }
              .not_to change { project.packages.count }

              expect(response).to have_gitlab_http_status(400)
            end
          end
        end

        context 'invalid package name' do
          let(:package_name) { "@#{group.path}/my_inv@@lid_package_name" }
          let(:params) { upload_params(package_name) }

          it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
            expect { upload_package_with_token(package_name, params) }
              .not_to change { project.packages.count }

            expect(response).to have_gitlab_http_status(400)
          end
        end
      end

      context 'scoped package' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name) }

        it 'creates npm package with file' do
          expect { upload_package_with_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
            .and change { Packages::PackageTag.count }.by(1)

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'package creation fails' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name) }

        it 'returns an error if the package already exists' do
          create(:npm_package, project: project, version: '1.0.1', name: "@#{group.path}/my_package_name")
          expect { upload_package_with_token(package_name, params) }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    def upload_package(package_name, params = {})
      put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params
    end

    def upload_package_with_token(package_name, params = {})
      upload_package(package_name, params.merge(access_token: token.token))
    end

    def upload_params(package_name)
      JSON.parse(
        fixture_file('npm/payload.json', dir: 'ee')
          .gsub('@root/npm-test', package_name))
    end
  end

  describe 'GET /api/v4/packages/npm/-/package/*package_name/dist-tags' do
    let(:package) { create(:npm_package, project: project) }
    let!(:package_tag1) { create(:package_tag, package: package) }
    let!(:package_tag2) { create(:package_tag, package: package) }
    let(:package_name) { package.name }
    let(:user) { create(:user) }
    let(:url) { "/packages/npm/-/package/#{package_name}/dist-tags" }

    subject { get api(url) }

    context 'with packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with public group' do
        context 'with authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns package tags', :maintainer
          it_behaves_like 'returns package tags', :developer
          it_behaves_like 'returns package tags', :reporter
          it_behaves_like 'returns package tags', :guest
        end

        context 'with unauthenticated user' do
          it_behaves_like 'returns package tags', :no_type
        end
      end

      context 'with private group' do
        let(:project) { create(:project, :private) }

        context 'with authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns package tags', :maintainer
          it_behaves_like 'returns package tags', :developer
          it_behaves_like 'returns package tags', :reporter
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :forbidden
        end
      end
    end

    context 'with packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it_behaves_like 'rejects package tags access', :no_type, :forbidden
    end
  end

  describe 'PUT /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    let(:package) { create(:npm_package, project: project) }
    let(:package_name) { package.name }
    let(:user) { create(:user) }
    let(:tag_name) { 'test' }
    let(:version) { package.version }
    let(:url) { "/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}" }

    subject { put api(url), env: { 'api.request.body': version } }

    context 'with packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with public group' do
        context 'with authenticated user' do
          subject { put api(url, user), env: { 'api.request.body': version } }

          it_behaves_like 'create package tag', :maintainer
          it_behaves_like 'create package tag', :developer
          it_behaves_like 'rejects package tags access', :reporter, :forbidden
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :unauthorized
        end
      end
    end

    context 'with packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it_behaves_like 'rejects package tags access', :no_type, :unauthorized
    end
  end

  describe 'DELETE /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    let(:package) { create(:npm_package, project: project) }
    let(:package_tag) { create(:package_tag, package: package) }
    let(:user) { create(:user) }
    let(:package_name) { package.name }
    let(:tag_name) { package_tag.name }
    let(:url) { "/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}" }

    subject { delete api(url) }

    context 'with packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with public group' do
        context 'with authenticated user' do
          subject { delete api(url, user) }

          it_behaves_like 'delete package tag', :maintainer
          it_behaves_like 'rejects package tags access', :developer, :forbidden
          it_behaves_like 'rejects package tags access', :reporter, :forbidden
          it_behaves_like 'rejects package tags access', :guest, :forbidden
        end

        context 'with unauthenticated user' do
          it_behaves_like 'rejects package tags access', :no_type, :unauthorized
        end
      end
    end

    context 'with packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it_behaves_like 'rejects package tags access', :no_type, :unauthorized
    end
  end

  def expect_a_valid_package_response
    expect(response).to have_gitlab_http_status(200)
    expect(response.content_type.to_s).to eq('application/json')
    expect(response).to match_response_schema('public_api/v4/packages/npm_package', dir: 'ee')
    expect(json_response['name']).to eq(package.name)
    expect(json_response['versions'][package.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee')
    expect(json_response['dist-tags']).to match_schema('public_api/v4/packages/npm_package_tags', dir: 'ee')
  end
end
