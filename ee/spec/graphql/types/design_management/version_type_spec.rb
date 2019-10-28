# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['DesignVersion'] do
  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it { expect(described_class).to have_graphql_fields(:id, :sha, :designs, :design_at_version, :designs_at_version) }
end
