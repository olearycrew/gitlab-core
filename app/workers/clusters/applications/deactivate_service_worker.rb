# frozen_string_literal: true

module Clusters
  module Applications
    class DeactivateServiceWorker
      include ApplicationWorker
      include ClusterQueue

      def perform(cluster_id, service_name)
        service = "#{service_name}_service".to_sym
        cluster = Clusters::Cluster.find_by_id(cluster_id)
        raise cluster_missing_error(service_name) unless cluster

        cluster.all_projects.with_service(service).find_each do |project|
          project.public_send(service).update!(active: false) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def cluster_missing_error(service)
        ActiveRecord::RecordNotFound.new("Can't deactivate #{service} services, host cluster not found! Some inconsistent records may left in database.")
      end
    end
  end
end
