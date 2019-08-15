# frozen_string_literal: true

module Types
  module DesignManagement
    module DesignFields
      include BaseInterface

      field_class Types::BaseField

      field :id, GraphQL::ID_TYPE, null: false
      field :project, Types::ProjectType, null: false
      field :issue, Types::IssueType, null: false
      field :filename, GraphQL::STRING_TYPE, null: false
      field :full_path, GraphQL::STRING_TYPE, null: false
      field :image, GraphQL::STRING_TYPE, null: false, extras: [:parent]
      field :diff_refs, Types::DiffRefsType, null: false, calls_gitaly: true
      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionsResolver,
            description: "All versions related to this design ordered newest first",
            extras: [:parent]
    end
  end
end
