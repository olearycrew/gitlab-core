# frozen_string_literal: true

module Clusters
  module Applications
    class PrometheusPostInstallationWorker
      include ApplicationWorker
      include ClusterQueue
      include ClusterApplications

      def perform(app_name, app_id)
        find_application(app_name, app_id) do |app|
          app.projects.find_each do |project|
            project.find_or_initialize_service('prometheus').update!(active: true)
          end
        end
      end
    end
  end
end
