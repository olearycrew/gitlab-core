# frozen_string_literal: true

class WafAnomalySummaryService < ::BaseService

  ANOMALY_THRESHOLD_EXCEEDED_MSG = 'Anomaly Score Exceeded'
  GITLAB_MANAGED_APPS_NAMESPACE = 'gitlab-managed-apps'
  MODSEC_LOG_CONTAINER_NAME = 'modsecurity-log'

  def initialize(environment:, interval: 'hour', from: 30.days.ago.iso8601, to: Time.now.iso8601)
    @environment = environment
    @interval = interval
    @from = from
    @to = to
  end

  def execute
    return if elasticsearch_client.nil?

    aggregate_results = anomaly_aggregates_by(@environment, @interval)

    {
      aggregations: aggregate_results.fetch("aggregations", {}),
      total_count: aggregate_results.dig("hits", "total"),
      interval: @interval,
      from: @from,
      to: @to,
      status: :success
    }
  end

  private

  def anomaly_aggregates_by(environment, interval)
    body = {
      query: query,
      aggs: aggregations(interval),
      size: 0 # no docs needed, only counts
    }

    elasticsearch_client.search(body: body)
  end

  def query
    {
      bool: {
        must: [
          {
            range: {
              "@timestamp".to_sym => {
                  gte: @from,
                  lte: @to
              }
            }
          },
          {
            match: {
              message: {
                query: ANOMALY_THRESHOLD_EXCEEDED_MSG
              }
            }
          },
          {
            match_phrase: {
              "kubernetes.container.name" => {
                query: MODSEC_LOG_CONTAINER_NAME
              }
            }
          },
          {
            match_phrase: {
              "kubernetes.namespace" => {
                query: GITLAB_MANAGED_APPS_NAMESPACE
              }
            }
          }
        ]
      }
    }
  end

  def aggregations(interval)
    {
      "amount_per_#{interval}".to_sym => {
        date_histogram: {
          field: "@timestamp",
          interval: interval
        }
      }
    }
  end

  def elasticsearch_client
    @client ||= @environment.deployment_platform.cluster.application_elastic_stack&.elasticsearch_client
  end
end
