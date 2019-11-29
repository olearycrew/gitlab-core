# frozen_string_literal: true

require 'spec_helper'

describe Groups::HooksController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with group_webhooks enabled' do
    before do
      stub_licensed_features(group_webhooks: true)
    end

    describe 'GET #index' do
      it 'is successfull' do
        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'POST #create' do
      it 'sets all parameters' do
        hook_params = {
          job_events: true,
          confidential_issues_events: true,
          enable_ssl_verification: true,
          issues_events: true,
          merge_requests_events: true,
          note_events: true,
          pipeline_events: true,
          push_events: true,
          tag_push_events: true,
          token: 'TEST TOKEN',
          url: 'http://example.com',
          wiki_page_events: true
        }

        post :create, params: { group_id: group.to_param, hook: hook_params }

        expect(response).to have_gitlab_http_status(302)
        expect(group.hooks.size).to eq(1)
        expect(group.hooks.first).to have_attributes(hook_params)
      end
    end

    describe 'GET #edit' do
      let(:hook) { create(:group_hook, group: group) }

      it 'is successfull' do
        get :edit, params: { group_id: group.to_param, id: hook }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:edit)
        expect(group.hooks.size).to eq(1)
      end
    end

    describe 'PATCH #update' do
      let(:hook) { create(:group_hook, group: group) }

      context 'valid params' do
        let(:hook_params) do
          {
            job_events: true,
            confidential_issues_events: true,
            enable_ssl_verification: true,
            issues_events: true,
            merge_requests_events: true,
            note_events: true,
            pipeline_events: true,
            push_events: true,
            tag_push_events: true,
            token: 'TEST TOKEN',
            url: 'http://example.com',
            wiki_page_events: true
          }
        end

        it 'is successfull' do
          patch :update, params: { group_id: group.to_param, id: hook, hook: hook_params }

          expect(response).to have_gitlab_http_status(302)
          expect(response).to redirect_to(group_hooks_path(group))
          expect(group.hooks.size).to eq(1)
          expect(group.hooks.first).to have_attributes(hook_params)
        end
      end

      context 'invalid params' do
        let(:hook_params) do
          {
            url: ''
          }
        end

        it 'renders "edit" template' do
          patch :update, params: { group_id: group.to_param, id: hook, hook: hook_params }

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:edit)
          expect(group.hooks.size).to eq(1)
          expect(group.hooks.first).not_to have_attributes(hook_params)
        end
      end
    end
  end

  context 'with group_webhooks disabled' do
    before do
      stub_licensed_features(group_webhooks: false)
    end

    describe 'GET #index' do
      it 'renders a 404' do
        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
