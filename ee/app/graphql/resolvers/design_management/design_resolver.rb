# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignResolver < BaseResolver
      argument :id, GraphQL::ID_TYPE,
               required: false,
               description: 'Find a design by its ID'

      argument :filename, GraphQL::STRING_TYPE,
               required: false,
               description: 'Find a design by its filename'

      def resolve(**args)
        find_design(args)
      end

      private

      def find_design(args)
        finder = if !args[:filename].present? && !args[:id].present?
                   raise ::Gitlab::Graphql::Errors::ArgumentError, "one of id or filename must be passed"
                 elsif args[:filename].present? && args[:id].present?
                   raise ::Gitlab::Graphql::Errors::ArgumentError, "only one of id or filename may be passed"
                 elsif args[:filename].present?
                   finder(filenames: [args[:filename]])
                 else
                   gid = GitlabSchema.parse_gid(args[:id], expected_type: ::DesignManagement::Design)
                   finder(ids: [gid.model_id])
                 end

        finder.execute.first
      end

      def issue
        object.issue
      end

      def user
        context[:current_user]
      end

      def finder(params)
        ::DesignManagement::DesignsFinder.new(issue, user, params)
      end
    end
  end
end
