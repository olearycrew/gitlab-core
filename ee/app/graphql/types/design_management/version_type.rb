# frozen_string_literal: true

module Types
  module DesignManagement
    class VersionType < ::Types::BaseObject
      # Just `Version` might be a bit to general to expose globally so adding
      # a `Design` prefix to specify the class exposed in GraphQL
      graphql_name 'DesignVersion'

      authorize :read_design

      field :id, ::GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :sha, ::GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :designs,
            ::Types::DesignManagement::DesignType.connection_type,
            null: false,
            description: "All designs that were changed in this version"
      field :designs_at_version,
            ::Types::DesignManagement::DesignAtVersionType.connection_type,
            null: false,
            description: "All designs as-of this version"
      field :design_at_version, ::Types::DesignManagement::DesignAtVersionType,
            null: true,
            description: "A specific design as-of this version" do
              argument :design_id, ::GraphQL::ID_TYPE, required: false, description: 'The GID of the design'
              argument :id, ::GraphQL::ID_TYPE, required: false, as: :gid, description: 'The GID of the DesignAtVersion'
            end

      def designs_at_version
        ::Gitlab::Graphql::Loaders::BatchModelLoader
          .new(Issue, object.issue_id).find
          .designs.visible_at_version(object)
          .map { |d| ::DesignManagement::DesignAtVersion.new(d, object) }
      end

      def design_at_version(design_id: nil, gid: nil)
        raise ::Gitlab::Graphql::Errors::ArgumentError, "only one of design_id or global id may be provided" if design_id && gid

        if design_id.present?
          design = GitlabSchema.object_from_id(design_id, expected_type: ::DesignManagement::Design)
          dav = ::DesignManagement::DesignAtVersion.new(design, object)
          return dav
        elsif gid.present?
          return GitlabSchema.object_from_id(gid, expected_type: ::DesignManagement::DesignAtVersion)
        else
          raise ::Gitlab::Graphql::Errors::ArgumentError, "at least one of design_id or global id is required"
        end
      end
    end
  end
end
