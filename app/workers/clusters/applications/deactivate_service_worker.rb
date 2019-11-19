# frozen_string_literal: true

module Clusters
  module Applications
    class DeactivateServiceWorker
      include ApplicationWorker
      include ClusterQueue

      def perform(cluster_id, service_name)
        service = "#{service_name}_service".to_sym
        Clusters::Cluster.find(cluster_id).all_projects.with_service(service).find_each do |project|
          project.public_send(service).update!(active: false) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
