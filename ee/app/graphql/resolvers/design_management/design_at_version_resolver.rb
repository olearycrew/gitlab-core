# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignAtVersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::DesignAtVersionType, null: true

      authorize :read_design

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'The Global ID of the design at this version'

      def resolve(id:)
        dav = GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::DesignAtVersion)
        return unless dav.present?

        # Ensure consistency with parent (e.g. design collection)
        if issue = object.try(:issue)
          return unless dav.design.issue_id == issue.id
        end

        dav if authorized_resource?(dav)
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
