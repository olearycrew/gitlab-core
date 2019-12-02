import { groupBySeverityLevel } from 'ee/security_dashboard/store/modules/vulnerable_projects/utils';

// eslint-disable-next-line import/prefer-default-export
export const severityGroups = ({ projects }) => groupBySeverityLevel(projects);
