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
            description: "All designs on this issue as-of this version",
            resolver: ::Resolvers::DesignManagement::DesignsAtVersionResolver

      field :design_at_version,
            ::Types::DesignManagement::DesignAtVersionType,
            null: false,
            description: "All designs on this issue as-of this version",
            resolver: ::Resolvers::DesignManagement::DesignsAtVersionResolver.single
    end
  end
end
