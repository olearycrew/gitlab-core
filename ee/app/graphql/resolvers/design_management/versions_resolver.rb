# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionsResolver < BaseResolver
      type Types::DesignManagement::VersionType.connection_type, null: false

      alias_method :design_or_collection, :object

      # For use in single resolution context
      argument :sha, GraphQL::STRING_TYPE,
               required: false,
               description: "The SHA256 of a specific version"

      def resolve(parent: nil, sha: false)
        find(earlier_or_equal_to: version(parent, sha))
      end

      private

      # Find an `at_version` argument passed to a parent node.
      #
      # If one is found, then a design collection further up the AST
      # has been filtered to reflect designs at that version, and so
      # for consistency we should only present versions up to the given
      # version here.
      def version(parent, sha)
        if sha.present?
          find(sha: sha).first
        elsif at_version = Gitlab::Graphql::FindArgumentInParent.find(parent, :at_version, limit_depth: 4)
          GitlabSchema.object_from_id(at_version).try(:sync)
        else
          nil
        end
      end

      def current_user
        context[:current_user]
      end

      def find(**params)
        ::DesignManagement::VersionsFinder.new(design_or_collection, current_user, params).execute
      end
    end
  end
end
