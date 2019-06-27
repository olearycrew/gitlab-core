require 'spec_helper'

describe Group do
  let(:group) { create(:group) }

  it { is_expected.to include_module(EE::Group) }

  describe 'associations' do
    it { is_expected.to have_many(:audit_events).dependent(false) }
    # shoulda-matchers attempts to set the association to nil to ensure
    # the presence check works, but since this is a private method that
    # method can't be called with a public_send.
    it { is_expected.to belong_to(:file_template_project).class_name('Project').without_validating_presence }
    it { is_expected.to have_many(:dependency_proxy_blobs) }
    it { is_expected.to have_one(:dependency_proxy_setting) }
  end

  describe 'scopes' do
    describe '.with_custom_file_templates' do
      let!(:excluded_group) { create(:group) }
      let(:included_group) { create(:group) }
      let(:project) { create(:project, namespace: included_group) }

      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)

        included_group.update!(file_template_project: project)
      end

      subject(:relation) { described_class.with_custom_file_templates }

      it { is_expected.to contain_exactly(included_group) }

      it 'preloads everything needed to show a valid checked_file_template_project' do
        group = relation.first

        expect { group.checked_file_template_project }.not_to exceed_query_limit(0)

        expect(group.checked_file_template_project).to be_present
      end
    end
  end

  describe 'validations' do
    context 'validates if custom_project_templates_group_id is allowed' do
      let(:subgroup_1) { create(:group, parent: group) }

      it 'rejects change if the assigned group is not a descendant' do
        group.custom_project_templates_group_id = create(:group).id

        expect(group).not_to be_valid
        expect(group.errors.messages[:custom_project_templates_group_id]).to eq ['has to be a descendant of the group']
      end

      it 'allows value if the current group is a top parent and the value is from a descendant' do
        subgroup = create(:group, parent: group)
        group.custom_project_templates_group_id = subgroup.id

        expect(group).to be_valid
      end

      it 'allows value if the current group is a subgroup and the value is from a descendant' do
        subgroup_1_1 = create(:group, parent: subgroup_1)
        subgroup_1.custom_project_templates_group_id = subgroup_1_1.id

        expect(group).to be_valid
      end

      it 'allows value when it is blank' do
        subgroup = create(:group, parent: group)
        group.update!(custom_project_templates_group_id: subgroup.id)

        group.custom_project_templates_group_id = ""

        expect(group).to be_valid
      end
    end
  end

  describe 'states' do
    it { is_expected.to be_ldap_sync_ready }

    context 'after the start transition' do
      it 'sets the last sync timestamp' do
        expect { group.start_ldap_sync }.to change { group.ldap_sync_last_sync_at }
      end
    end

    context 'after the finish transition' do
      it 'sets the state to started' do
        group.start_ldap_sync

        expect(group).to be_ldap_sync_started

        group.finish_ldap_sync
      end

      it 'sets last update and last successful update to the same timestamp' do
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .to eq(group.ldap_sync_last_successful_update_at)
      end

      it 'clears previous error message on success' do
        group.start_ldap_sync
        group.mark_ldap_sync_as_failed('Error')
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_error).to be_nil
      end
    end

    context 'after the fail transition' do
      it 'sets the state to failed' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group).to be_ldap_sync_failed
      end

      it 'sets last update timestamp but not last successful update timestamp' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .not_to eq(group.ldap_sync_last_successful_update_at)
      end
    end
  end

  describe '#mark_ldap_sync_as_failed' do
    it 'sets the state to failed' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Error')

      expect(group).to be_ldap_sync_failed
    end

    it 'sets the error message' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Something went wrong')

      expect(group.ldap_sync_error).to eq('Something went wrong')
    end

    it 'is graceful when current state is not valid for the fail transition' do
      expect(group).to be_ldap_sync_ready
      expect { group.mark_ldap_sync_as_failed('Error') }.not_to raise_error
    end
  end

  describe '#actual_size_limit' do
    let(:group) { build(:group) }

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the value set globally' do
      expect(group.actual_size_limit).to eq(50)
    end

    it 'returns the value set locally' do
      group.update_attribute(:repository_size_limit, 75)

      expect(group.actual_size_limit).to eq(75)
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      group = create(:group)
      group.update_column(:repository_size_limit, 8.exabytes - 1)

      group.reload

      expect(group.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe '#file_template_project' do
    it { expect(group.private_methods).to include(:file_template_project) }

    before do
      stub_licensed_features(custom_file_templates_for_namespace: true)
    end

    it { expect(group.private_methods).to include(:file_template_project) }

    context 'validation' do
      let(:project) { create(:project, namespace: group) }

      it 'is cleared if invalid' do
        invalid_project = create(:project)

        group.file_template_project_id = invalid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to be_nil
      end

      it 'is permitted if valid' do
        valid_project = create(:project, namespace: group)

        group.file_template_project_id = valid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to eq(valid_project.id)
      end
    end
  end

  describe '#checked_file_template_project' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project)
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: false)
      end

      it 'returns nil for a valid project' do
        group.file_template_project = valid_project

        is_expected.to be_nil
      end
    end
  end

  describe '#checked_file_template_project_id' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project_id }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns the ID for a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project.id)
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(custom_file_templates_for_namespace: false)
        end

        it 'returns nil for a valid project' do
          group.file_template_project = valid_project

          is_expected.to be_nil
        end
      end
    end
  end

  describe 'Vulnerabilities::Occurrence collection methods' do
    describe 'vulnerabilities finder methods' do
      let(:project) { create(:project, namespace: group) }
      let(:external_project) { create(:project) }
      let(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }

      let!(:old_vuln) { create_vulnerability(project) }
      let!(:new_vuln) { create_vulnerability(project) }
      let!(:external_vuln) { create_vulnerability(external_project) }
      let!(:failed_vuln) { create_vulnerability(project, failed_pipeline) }

      before do
        pipeline_ran_against_new_sha = create(:ci_pipeline, :success, project: project, sha: '123')
        new_vuln.pipelines << pipeline_ran_against_new_sha
      end

      def create_vulnerability(project, pipeline = nil)
        pipeline ||= create(:ci_pipeline, :success, project: project)
        create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project)
      end

      describe '#latest_vulnerabilities' do
        subject { group.latest_vulnerabilities }

        it 'returns vulns only for the latest successful pipelines of projects belonging to the group' do
          is_expected.to contain_exactly(new_vuln)
        end

        context 'with vulnerabilities from other branches' do
          let!(:branch_pipeline) { create(:ci_pipeline, :success, project: project, ref: 'feature-x') }
          let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: project) }

          # TODO: This should actually fail and we must scope vulns
          # per branch as soon as we store them for other branches
          # Dependent on https://gitlab.com/gitlab-org/gitlab-ee/issues/9524
          it 'includes vulnerabilities from all branches' do
            is_expected.to contain_exactly(branch_vuln)
          end
        end
      end

      describe '#latest_vulnerabilities_with_sha' do
        subject { group.latest_vulnerabilities_with_sha }

        it 'returns vulns only for the latest successful pipelines of projects belonging to the group' do
          is_expected.to contain_exactly(new_vuln)
        end

        it { is_expected.to all(respond_to(:sha)) }

        context 'with vulnerabilities from other branches' do
          let!(:branch_pipeline) { create(:ci_pipeline, :success, project: project, ref: 'feature-x') }
          let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: project) }

          # TODO: This should actually fail and we must scope vulns
          # per branch as soon as we store them for other branches
          # Dependent on https://gitlab.com/gitlab-org/gitlab-ee/issues/9524
          it 'includes vulnerabilities from all branches' do
            is_expected.to contain_exactly(branch_vuln)
          end
        end
      end

      describe '#all_vulnerabilities' do
        subject { group.all_vulnerabilities }

        it 'returns vulns for all successful pipelines of projects belonging to the group' do
          is_expected.to contain_exactly(old_vuln, new_vuln, new_vuln)
        end

        context 'with vulnerabilities from other branches' do
          let!(:branch_pipeline) { create(:ci_pipeline, :success, project: project, ref: 'feature-x') }
          let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: project) }

          # TODO: This should actually fail and we must scope vulns
          # per branch as soon as we store them for other branches
          # Dependent on https://gitlab.com/gitlab-org/gitlab-ee/issues/9524
          it 'includes vulnerabilities from all branches' do
            is_expected.to contain_exactly(old_vuln, new_vuln, new_vuln, branch_vuln)
          end
        end
      end
    end
  end

  describe '#group_project_template_available?' do
    subject { group.group_project_template_available? }

    context 'licensed' do
      before do
        stub_licensed_features(group_project_templates: true)
      end

      it 'returns true for licensed instance' do
        is_expected.to be true
      end

      context 'when in need of checking plan' do
        before do
          allow(Gitlab::CurrentSettings.current_application_settings)
            .to receive(:should_check_namespace_plan?) { true }
        end

        it 'returns true for groups in proper plan' do
          create(:gitlab_subscription, namespace: group, hosted_plan: create(:gold_plan))

          is_expected.to be true
        end

        it 'returns true for groups with group template already set within grace period' do
          group.update!(custom_project_templates_group_id: create(:group, parent: group).id)
          group.reload

          Timecop.freeze(GroupsWithTemplatesFinder::CUT_OFF_DATE - 1.day) do
            is_expected.to be true
          end
        end

        it 'returns false for groups with group template already set after grace period' do
          group.update!(custom_project_templates_group_id: create(:group, parent: group).id)
          group.reload

          Timecop.freeze(GroupsWithTemplatesFinder::CUT_OFF_DATE + 1.day) do
            is_expected.to be false
          end
        end
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(group_project_templates: false)
        end

        it 'returns false unlicensed instance' do
          is_expected.to be false
        end
      end
    end
  end

  describe '#saml_discovery_token' do
    it 'returns existing tokens' do
      group = create(:group, saml_discovery_token: 'existing')

      expect(group.saml_discovery_token).to eq 'existing'
    end

    context 'when missing on read' do
      it 'generates a token' do
        expect(group.saml_discovery_token.length).to eq 8
      end

      it 'saves the generated token' do
        expect { group.saml_discovery_token }.to change { group.reload.read_attribute(:saml_discovery_token) }
      end

      context 'in read only mode' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          allow(group).to receive(:create_or_update).and_raise(ActiveRecord::ReadOnlyRecord)
        end

        it "doesn't raise an error as that could expose group existance" do
          expect { group.saml_discovery_token }.not_to raise_error
        end

        it 'returns a random value to prevent access' do
          expect(group.saml_discovery_token).not_to be_blank
        end
      end
    end
  end

  describe "#insights_config" do
    context 'when group has no Insights project configured' do
      it 'returns the default config' do
        expect(group.insights_config).to eq(group.default_insights_config)
      end
    end

    context 'when group has an Insights project configured without a config file' do
      before do
        project = create(:project, group: group)
        group.create_insight!(project: project)
      end

      it 'returns the default config' do
        expect(group.insights_config).to eq(group.default_insights_config)
      end
    end

    context 'when group has an Insights project configured' do
      before do
        project = create(:project, :custom_repo, group: group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
        group.create_insight!(project: project)
      end

      context 'with a valid config file' do
        let(:insights_file_content) { 'key: monthlyBugsCreated' }

        it 'returns the insights config data' do
          insights_config = group.insights_config

          expect(insights_config).to eq(key: 'monthlyBugsCreated')
        end
      end

      context 'with an invalid config file' do
        let(:insights_file_content) { ': foo bar' }

        it 'returns the insights config data' do
          expect(group.insights_config).to be_nil
        end
      end
    end
  end
end
