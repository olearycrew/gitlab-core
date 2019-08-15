# frozen_string_literal: true

module EE
  module Types
    module QueryType
      extend ActiveSupport::Concern

      prepended do
        field :design_management_version, ::Types::DesignManagement::VersionType,
              null: true,
              resolver: ::Resolvers::DesignManagement::VersionResolver,
              description: 'Find a version'

        field :design_management_design_at_version, ::Types::DesignManagement::DesignAtVersionType,
              null: true,
              resolver: ::Resolvers::DesignManagement::DesignAtVersionResolver,
              description: 'Find a design pinned as-of a version'
      end
    end
  end
end
