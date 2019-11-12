# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::PrometheusActivateServiceWorker, '#perform' do
  let(:app) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
  let(:app_name) { app.name }
  let(:app_id) { app.id }

  context 'app exists' do
    context 'cluster type  is group' do
      set(:group) { create(:group) }
      set(:project) { create(:project, group: group) }
      let(:cluster) { create(:cluster_for_group, :with_installed_helm, groups: [group]) }

      it 'ensures Prometheus service is activated' do
        expect { described_class.new.perform(app_name, app_id) }.to change { project.reload.prometheus_service&.active }.from(nil).to(true)
      end
    end

    context 'cluster type  is project' do
      let(:project) { create(:project) }
      let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }

      it 'ensures Prometheus service is activated' do
        expect { described_class.new.perform(app_name, app_id) }.to change { project.reload.prometheus_service&.active }.from(nil).to(true)
      end
    end
  end

  context 'app does not exist' do
    let(:app_id) { 0 }
    let(:app) { create(:clusters_applications_prometheus, :installed) }

    it 'does not call the check service' do
      expect { described_class.new.perform(app_name, app_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
