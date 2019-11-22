# frozen_string_literal: true

shared_examples 'returning response status' do |status|
  it "returns #{status} response" do
    subject

    expect(response).to have_gitlab_http_status(status)
  end
end
