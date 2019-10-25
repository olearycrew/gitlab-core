# frozen_string_literal: true

module Types
  module DesignManagement
    module DesignFields
      include BaseInterface

      field_class Types::BaseField

      field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :project, Types::ProjectType, null: false # rubocop:disable Graphql/Descriptions
      field :issue, Types::IssueType, null: false # rubocop:disable Graphql/Descriptions
      field :filename, GraphQL::STRING_TYPE, null: false # rubocop:disable GraphQL/Descriptions
      field :full_path, GraphQL::STRING_TYPE, null: false # rubocop:disable GraphQL/Descriptions
      field :image, GraphQL::STRING_TYPE, null: false, extras: [:parent] # rubocop:disable GraphQL/Descriptions
      field :diff_refs, Types::DiffRefsType,
            null: false,
            calls_gitaly: true,
            extras: [:parent],
            description: 'The diff refs for this design'
      field :event, Types::DesignManagement::DesignVersionEventEnum,
            null: false,
            extras: [:parent],
            description: 'How this design was changed in the current version'
      field :notes_count,
            GraphQL::INT_TYPE,
            null: false,
            method: :user_notes_count,
            description: 'The total count of user-created notes for this design'

      def diff_refs(parent:)
        version = cached_stateful_version(parent)
        version.diff_refs
      end

      def image(parent:)
        sha = cached_stateful_version(parent).sha

        Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)
      end

      def event(parent:)
        version = cached_stateful_version(parent)

        action = cached_actions_for_version(version)[design.id]

        action&.event || Types::DesignManagement::DesignVersionEventEnum::NONE
      end

      def cached_actions_for_version(version)
        Gitlab::SafeRequestStore.fetch(['DesignFields', 'actions_for_version', version.id]) do
          version.actions.to_h { |dv| [dv.design_id, dv] }
        end
      end
    end
  end
end
