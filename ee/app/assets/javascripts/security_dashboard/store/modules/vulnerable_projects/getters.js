import { groupBySeverityLevel } from 'ee/security_dashboard/store/modules/vulnerable_projects/utils';

export const severityGroups = ({ projects }) => groupBySeverityLevel(projects);

export default () => {};
