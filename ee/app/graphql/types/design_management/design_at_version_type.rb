# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignAtVersionType < BaseObject
      graphql_name 'DesignAtVersion'

      description 'A design pinned to a specific version'

      authorize :read_design

      delegate :id, :design, :version, to: :object
      delegate :project, :issue, :filename, :full_path, :diff_refs, to: :design

      implements(Types::DesignManagement::DesignFields)

      field :version,
            Types::DesignManagement::VersionType,
            null: false,
            description: "The version this design-at-versions is pinned to"

      def image(_args)
        project = Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, design.project_id).find

        Gitlab::Routing.url_helpers.project_design_url(project, design, version.sha)
      end
    end
  end
end
