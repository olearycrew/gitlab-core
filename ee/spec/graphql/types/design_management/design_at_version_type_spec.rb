# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['DesignAtVersion'] do
  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      project
      issue
      filename
      full_path
      image
      diff_refs
      event
      notes_count

      id
      version
      design
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
