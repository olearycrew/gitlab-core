# frozen_string_literal: true

require 'spec_helper'

describe 'Query' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user) }
  let(:current_user) { developer }

  describe '.designManagementDesignAtVersion' do
    include DesignManagementTestHelpers

    let_it_be(:version) { create(:design_version, issue: issue) }
    let_it_be(:design) { version.designs.first }
    let_it_be(:design_at_version) do
      ::DesignManagement::DesignAtVersion.new(design: design, version: version)
    end

    let(:field) { 'designManagementDesignAtVersion' }
    let(:query_result) { graphql_data[field] }

    def global_id(obj)
      GitlabSchema.id_from_object(obj).to_s
    end

    let(:query) do
      graphql_query_for(
        field,
        { 'id' => global_id(design_at_version) },
        <<~FIELDS
        id
        filename
        version { id sha }
        design { id }
        issue { title iid }
        project { id fullPath }
      FIELDS
      )
    end

    before do
      enable_design_management
      project.add_developer(developer)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    context 'the current user is not able to read designs' do
      let(:current_user) { create(:user) }

      it 'does not retrieve the record' do
        expect(query_result).to be_nil
      end
    end

    context 'the current user is able to read designs' do
      it 'fetches the expected data, including the correct associations' do
        expect(query_result).to eq(
          'id' => global_id(design_at_version),
          'filename' => design_at_version.design.filename,
          'version' => { 'id' => global_id(version), 'sha' => version.sha },
          'design'  => { 'id' => global_id(design) },
          'issue'   => { 'title' => issue.title, 'iid' => issue.iid.to_s },
          'project' => { 'id' => global_id(project), 'fullPath' => project.full_path }
        )
      end
    end
  end
end
