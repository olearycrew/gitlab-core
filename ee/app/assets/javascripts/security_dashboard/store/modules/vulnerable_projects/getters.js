import { groupBySeverityLevel } from 'ee/security_dashboard/store/modules/vulnerable_projects/utils';

export const severityGroups = ({ projects }) => groupBySeverityLevel(projects);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-foss#52179 is merged
export default () => {};
