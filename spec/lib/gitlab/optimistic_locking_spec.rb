require 'spec_helper'

describe Gitlab::OptimisticLocking, lib: true do
  describe '#retry_lock' do
    let!(:pipeline) { create(:ci_pipeline) }
    let!(:pipeline2) { Ci::Pipeline.find(pipeline.id) }

    it 'does not reload object if state changes' do
      expect(pipeline).not_to receive(:reload)
      expect(pipeline).to receive(:succeed).and_call_original

      described_class.retry_lock(pipeline) do |subject|
        subject.succeed
      end
    end

    it 'retries action if exception is raised' do
      pipeline.succeed

      expect(pipeline2).to receive(:reload).and_call_original
      expect(pipeline2).to receive(:drop).twice.and_call_original

      described_class.retry_lock(pipeline2) do |subject|
        subject.drop
      end
    end
  end
end
