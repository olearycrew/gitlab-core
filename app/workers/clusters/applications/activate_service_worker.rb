# frozen_string_literal: true

module Clusters
  module Applications
    class ActivateServiceWorker
      include ApplicationWorker
      include ClusterQueue

      def perform(cluster_id, service)
        cluster = Clusters::Cluster.find_by_id(cluster_id)
        return unless cluster

        cluster.all_projects.find_each do |project|
          project.find_or_initialize_service(service).update!(active: true)
        end
      end
    end
  end
end
