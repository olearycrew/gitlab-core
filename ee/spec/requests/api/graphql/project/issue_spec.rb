# frozen_string_literal: true

require 'spec_helper'

describe 'Query.project(fullPath).issue(iid)' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user) }
  let(:current_user) { developer }

  let(:project_params) { { 'fullPath' => project.full_path } }
  let(:issue_params) { { 'iid' => issue.iid } }
  let(:issue_fields) { 'title' }

  let(:query) do
    graphql_query_for('project', project_params, project_fields)
  end

  let(:project_fields) do
    query_graphql_field(:issue, issue_params, issue_fields)
  end

  before do
    project.add_developer(developer)
  end

  shared_examples 'a failure to find anything' do
    it 'finds nothing' do
      post_query

      data = graphql_data.dig(*path)

      expect(data).to be_nil
    end
  end

  let(:post_query) { post_graphql(query, current_user: current_user) }

  describe '.designCollection' do
    include DesignManagementTestHelpers

    let_it_be(:design_a) { create(:design, issue: issue) }
    let_it_be(:version_a) { create(:design_version, issue: issue, created_designs: [design_a]) }

    let(:issue_fields) do
      query_graphql_field(:design_collection, dc_params, design_collection_fields)
    end

    let(:dc_params) { nil }
    let(:design_collection_fields) { nil }

    before do
      enable_design_management
    end

    describe '.design' do
      let(:design) { design_a }
      let(:path) { %w[project issue designCollection design] }

      let(:design_collection_fields) do
        query_graphql_field(:design, design_params, design_fields)
      end

      let(:design_fields) do
        [query_graphql_field(:filename), query_graphql_field(:project, nil, query_graphql_field(:id))]
      end

      context 'without parameters' do
        let(:design_params) { nil }

        it 'raises an error' do
          post_query

          expect(graphql_errors).to include(custom_graphql_error(path, a_string_matching(%r/id or filename/)))
        end
      end

      context 'by ID' do
        let(:design_params) { { id: global_id_of(design) } }

        it 'retrieves the Design' do
          post_query

          data = graphql_data.dig(*path)

          expect(data).to match(
            a_hash_including('filename' => design.filename,
                             'project' => a_hash_including('id' => global_id_of(project)))
          )
        end

        context 'for an unauthorized user' do
          let(:current_user) { create(:user) }

          it_behaves_like 'a failure to find anything'
        end
      end

      context 'attempting to retrieve a Design object from a different issue' do
        let(:issue_b) { create(:issue, project: project) }
        let(:design) { create(:design, issue: issue_b) }
        let(:design_params) { { id: global_id_of(design) } }

        it_behaves_like 'a failure to find anything'
      end
    end

    describe '.designAtVersion' do
      let(:design) { design_a }
      let(:version) { version_a }
      let(:dav) { ::DesignManagement::DesignAtVersion.new(design: design, version: version) }
      let(:path) { %w[project issue designCollection designAtVersion] }

      let(:design_collection_fields) do
        query_graphql_field(:design_at_version, dav_params, dav_fields)
      end

      let(:dav_fields) do
        [query_graphql_field(:filename), query_graphql_field(:version, nil, query_graphql_field(:id))]
      end

      context 'without parameters' do
        let(:dav_params) { nil }

        it 'raises an error' do
          post_query

          expect(graphql_errors).to include(missing_required_argument(path, :id))
        end
      end

      context 'by ID' do
        let(:dav_params) { { id: global_id_of(dav) } }

        it 'retrieves the DesignAtVersion' do
          post_query

          data = graphql_data.dig(*path)

          expect(data).to match(
            a_hash_including('filename' => design.filename,
                             'version' => a_hash_including('id' => global_id_of(version)))
          )
        end

        context 'the user is unauthorized' do
          let(:current_user) { create(:user) }

          it_behaves_like 'a failure to find anything'
        end
      end

      context 'attempting to retrieve a DesignAtVersion object from a different issue' do
        let(:issue_b) { create(:issue, project: project) }
        let(:design) { create(:design, issue: issue_b) }
        let(:version) { create(:design_version, issue: issue_b, created_designs: [design_a]) }
        let(:dav_params) { { id: global_id_of(dav) } }

        it_behaves_like 'a failure to find anything'
      end
    end
  end
end
