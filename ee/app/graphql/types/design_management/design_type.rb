# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'

      authorize :read_design

      alias_method :design, :object

      field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :project, Types::ProjectType, null: false # rubocop:disable Graphql/Descriptions
      field :issue, Types::IssueType, null: false # rubocop:disable Graphql/Descriptions
      implements(Types::Notes::NoteableType)
      implements(Types::DesignManagement::DesignFields)

      field :notes_count,
            GraphQL::INT_TYPE,
            null: false,
            method: :user_notes_count,
            description: 'The total count of user-created notes for this design'

      def image(parent:)
        sha = cached_stateful_version(parent).sha

        Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)
      end

      def event(parent:)
        version = cached_stateful_version(parent)

        action = cached_actions_for_version(version)[design.id]

        action&.event || Types::DesignManagement::DesignVersionEventEnum::NONE
      end

      # Returns a `DesignManagement::Version` for this query based on the
      # `atVersion` argument passed to a parent node if present, or otherwise
      # the most recent `Version` for the issue.
      def cached_stateful_version(parent_node)
        version_gid = Gitlab::Graphql::FindArgumentInParent.find(parent_node, :at_version)

        # Caching is scoped to an `issue_id` to allow us to cache the
        # most recent `Version` for an issue
        Gitlab::SafeRequestStore.fetch([request_cache_base_key, 'stateful_version', object.issue_id, version_gid]) do
          if version_gid
            GitlabSchema.object_from_id(version_gid)&.sync
          else
            object.issue.design_versions.most_recent
          end
        end
      end

      def cached_actions_for_version(version)
        Gitlab::SafeRequestStore.fetch([request_cache_base_key, 'actions_for_version', version.id]) do
          version.actions.to_h { |dv| [dv.design_id, dv] }
        end
      end

      def request_cache_base_key
        self.class.name
      end
    end
  end
end
