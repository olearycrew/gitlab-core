# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard snippets' do
  context 'when the project has snippets' do
    let(:project) { create(:project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)
      sign_in(project.owner)
      visit dashboard_snippets_path
    end

    it_behaves_like 'paginated snippets'
  end

  context 'when there are no project snippets', :js do
    let(:project) { create(:project, :public) }
    before do
      sign_in(project.owner)
      visit dashboard_snippets_path
    end

    it 'shows the empty state when there are no snippets' do
      element = page.find('.row.empty-state')

      expect(element).to have_content("Snippets are small pieces of code or notes that you want to keep.")
      expect(element.find('.svg-content img')['src']).to have_content('illustrations/snippets_empty')
    end
  end

  context 'filtering by visibility' do
    let(:user) { create(:user) }
    let!(:snippets) do
      [
        create(:personal_snippet, :public, author: user),
        create(:personal_snippet, :internal, author: user),
        create(:personal_snippet, :private, author: user),
        create(:personal_snippet, :secret, author: user),
        create(:personal_snippet, :public)
      ]
    end
    let(:flag_value) { true }

    before do
      stub_feature_flags(secret_snippets: flag_value)

      sign_in(user)

      visit dashboard_snippets_path
    end

    it 'contains 5 snippet sections' do
      expect(page).to have_selector('.snippet-scope-menu li', count: 5)
    end

    it 'contains all snippets of logged user' do
      expect(page).to have_selector('.snippet-row', count: 4)

      expect(page).to have_content(snippets[0].title)
      expect(page).to have_content(snippets[1].title)
      expect(page).to have_content(snippets[2].title)
      expect(page).to have_content(snippets[3].title)
    end

    it 'contains all private snippets of logged user when clicking on private' do
      click_link('Private')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[2].title)
    end

    it 'contains all internal snippets of logged user when clicking on internal' do
      click_link('Internal')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[1].title)
    end

    it 'contains all public snippets of logged user when clicking on public' do
      click_link('Public')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[0].title)
    end

    it 'contains all secret snippets of logged user when clicking on secret' do
      click_link('Secret')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[3].title)
    end

    context 'when secret_snippets feature flag is disabled' do
      let(:flag_value) { false }

      it 'does not contain secret snippets section' do
        expect(page).to have_selector('.snippet-scope-menu li', count: 4)
      end
    end
  end
end
