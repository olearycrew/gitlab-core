# frozen_string_literal: true

module Projects
  module Security
    class WafAnomaliesController < Projects::ApplicationController

      before_action :authorize_read_waf_anomalies!

      def summary
        # TODO
        # ::Gitlab::UsageCounters::WafAnomalies.increment(project.id)

        @environment = ::Environment.find(query_params.delete(:environment_id))

        head :not_found unless environment

        respond_to do |format|
          format.json do
            # render json: WafAnomalySummarySerializer.new.represent(anomaly_summary)
            render json: anomaly_summary
          end
        end
      end

      private

      def anomaly_summary
        WafAnomalySummaryService.new(environment: @environment, **query_params.compact).execute
      end

      def query_params
        params.permit(:environment_id, :interval, :from, :to)
      end

      def authorize_read_waf_anomalies!
        # render_403 unless can?(current_user, :read_waf_anomalies, project)
      end
    end
  end
end