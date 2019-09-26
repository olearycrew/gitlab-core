require 'spec_helper'

describe 'User views issue designs', :js do
  include DesignManagementTestHelpers

  set(:project) { create(:project_empty_repo, :public) }
  set(:issue) { create(:issue, project: project) }

  before do
    enable_design_management

    create(:design, :with_file, issue: issue)
  end

  context 'navigates from the issue view' do
    before do
      visit project_issue_path(project, issue)
      click_link 'Designs'
      wait_for_requests
    end

    it 'fetches list of designs' do
      expect(page).to have_selector('.js-design-list-item', count: 1)
    end
  end

  context 'navigates directly to the design view' do
    before do
      visit designs_project_issue_path(project, issue)
    end

    it 'expands the sidebar' do
      expect(page).to have_selector('.layout-page.right-sidebar-expanded')
    end
  end
end
