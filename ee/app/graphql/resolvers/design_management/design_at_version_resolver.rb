# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignAtVersionResolver < BaseResolver
      type Types::DesignManagement::VersionType, null: true

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'The Global ID of the design at this version'

      def resolve(id:)
        GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::DesignAtVersion)
      end
    end
  end
end
