module Elastic
  module MilestonesSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings _parent: { type: 'project' } do
        indexes :id,          type: :integer
        indexes :title,       type: :text,
                              index_options: 'offsets'
        indexes :description, type: :text,
                              index_options: 'offsets'
        indexes :project_id,  type: :integer
        indexes :created_at,  type: :date
        indexes :updated_at,  type: :date
      end

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        data = {}

        [:id, :title, :description, :project_id, :created_at, :updated_at].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data
      end

      def self.nested?
        true
      end

      def self.elastic_search(query, options: {})
        options[:in] = %w(title^2 description)

        query_hash = basic_query_hash(options[:in], query)

        query_hash = project_ids_filter(query_hash, options)

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
