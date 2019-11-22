# frozen_string_literal: true
require 'spec_helper'

describe Packages::RemovePackageTagService do
  let!(:package_tag) { create(:package_tag) }

  describe '#execute' do
    subject { described_class.new(package_tag).execute }

    context 'with existing tag' do
      it { expect { subject }.to change { Packages::PackageTag.count }.by(-1) }
    end

    context 'with nil' do
      subject { described_class.new(nil) }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end
