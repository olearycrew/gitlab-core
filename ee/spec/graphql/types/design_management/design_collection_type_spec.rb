# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['DesignCollection'] do
  let(:expected_fields) do
    [:project, :issue, :designs, :versions, :version, :designAtVersion, :design]
  end

  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it { expect(described_class).to have_graphql_fields(*expected_fields) }
end
