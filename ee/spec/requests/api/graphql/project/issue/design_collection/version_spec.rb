# frozen_string_literal: true

require 'spec_helper'

describe 'Query.project(fullPath).issue(iid).designCollection.version(sha)' do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:stranger) { create(:user) }
  let_it_be(:old_version) do
    create(:design_version, issue: issue,
           created_designs: create_list(:design, 3, issue: issue))
  end
  let_it_be(:version) do
    create(:design_version, issue: issue,
           modified_designs: old_version.designs,
           created_designs: create_list(:design, 2, issue: issue),
           deleted_designs: create_list(:design, 1, issue: issue))
  end

  let(:current_user) { developer }

  let(:query) { graphql_query_for('project', { fullPath: project.full_path }, project_fields) }

  let(:project_fields) do
    query_graphql_field(:issue, { iid: issue.iid.to_s }, issue_fields)
  end

  let(:issue_fields) do
    query_graphql_field(:design_collection, nil, design_collection_fields)
  end

  let(:design_collection_fields) do
    query_graphql_field(:version, { sha: version.sha }, version_fields)
  end

  let(:post_query) { post_graphql(query, current_user: current_user) }
  let(:path_prefix) { %w[project issue designCollection version] }

  let(:data) { graphql_data.dig(*path) }

  before do
    enable_design_management
    project.add_developer(developer)
  end

  describe 'scalar fields' do
    let(:path) { path_prefix }
    let(:version_fields) { query_graphql_field(:sha) }

    before do
      post_query
    end

    { id: ->(x) { x.to_global_id.to_s }, sha: ->(x) { x.sha } }.each do |field, value|
      describe ".#{field}" do
        let(:version_fields) { query_graphql_field(field) }

        it "retrieves the #{field}" do
          expect(data).to match(a_hash_including(field.to_s => value[version]))
        end
      end
    end
  end

  describe 'design_at_version' do
    let(:path) { path_prefix + %w[designAtVersion] }
    let(:design) { issue.designs.visible_at_version(version).to_a.sample }
    let(:design_at_version) do
      ::DesignManagement::DesignAtVersion.new(design: design, version: version)
    end

    let(:version_fields) do
      query_graphql_field(:design_at_version, dav_params, 'id filename')
    end

    shared_examples :finds_dav do
      it 'finds all the designs as of the given version' do
        post_query

        expect(data).to match(
          a_hash_including(
            'id' => global_id_of(design_at_version),
            'filename' => design.filename
          ))
      end

      context 'when the current_user is not authorized' do
        let(:current_user) { stranger }

        it 'returns nil' do
          post_query

          expect(data).to be_nil
        end
      end
    end

    context 'by ID' do
      let(:dav_params) { { id: global_id_of(design_at_version) } }

      include_examples :finds_dav
    end

    context 'by filename' do
      let(:dav_params) { { filename: design.filename } }

      include_examples :finds_dav
    end

    context 'by design_id' do
      let(:dav_params) { { design_id: global_id_of(design) } }

      include_examples :finds_dav
    end
  end

  describe 'designs_at_version' do
    let(:path) { path_prefix + %w[designsAtVersion edges] }
    let(:version_fields) do
      query_graphql_field(:designs_at_version, nil, 'edges { node { id filename } }')
    end

    let(:results) do
      issue.designs.visible_at_version(version).map do |d|
        dav = ::DesignManagement::DesignAtVersion.new(design: d, version: version)
        { 'id' => global_id_of(dav), 'filename' => d.filename }
      end
    end

    it 'finds all the designs as of the given version' do
      post_query

      expect(data.pluck('node')).to match_array(results)
    end
  end

  describe 'designs' do
    let(:path) { path_prefix + %w[designs edges] }
    let(:version_fields) do
      query_graphql_field(:designs, nil, 'edges { node { id filename } }')
    end

    let(:results) do
      version.designs.map do |design|
        { 'id' => global_id_of(design), 'filename' => design.filename }
      end
    end

    it 'finds all the designs as of the given version' do
      post_query

      expect(data.pluck('node')).to match_array(results)
    end
  end
end
