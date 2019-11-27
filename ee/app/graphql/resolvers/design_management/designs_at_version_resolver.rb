# frozen_string_literal: true

module Resolvers
  module DesignManagement
    # Resolver for DesignAtVersion objects given an implicit version context
    class DesignsAtVersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::DesignAtVersionType, null: true

      authorize :read_design

      # For use in single resolver context
      argument :id, GraphQL::ID_TYPE,
               required: false,
               as: :design_at_version_id,
               description: 'The ID of the DesignAtVersion'
      argument :design_id, GraphQL::ID_TYPE,
               required: false,
               description: 'The ID of a specific design'
      argument :filename, GraphQL::STRING_TYPE,
               required: false,
               description: 'The filename of a specific design'

      # For use in default (collection) context
      argument :ids,
               [GraphQL::ID_TYPE],
               required: false,
               description: 'Filters designs by their ID'
      argument :filenames,
               [GraphQL::STRING_TYPE],
               required: false,
               description: 'Filters designs by their filename'

      def resolve(ids: [], filenames: [], design_id: nil, filename: nil, design_at_version_id: nil)
        dav_by_id = specific_design_at_version(design_at_version_id)

        design_ids = Array.wrap(design_id).concat(ids).map do |id|
          GitlabSchema.parse_gid(id, expected_type: ::DesignManagement::Design).model_id
        end

        filenames = Array.wrap(filename).concat(filenames)

        dav_by_id.concat(find(design_ids, filenames).execute.map { |d| make(d) })
      end

      private

      def specific_design_at_version(id)
        return [] unless id.present? && Ability.allowed?(current_user, :read_design, issue)

        [GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::DesignAtVersion)]
          .select { |dav| dav.design.issue_id == issue.id && dav.version.id == version.id }
      end

      def find(ids, filenames)
        ::DesignManagement::DesignsFinder.new(issue, current_user,
                                              ids: ids,
                                              filenames: filenames,
                                              visible_at_version: version)
      end

      def current_user
        context[:current_user]
      end

      def issue
        version.issue
      end

      def version
        object
      end

      def make(design)
        ::DesignManagement::DesignAtVersion.new(design: design, version: version)
      end
    end
  end
end
