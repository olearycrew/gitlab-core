import { groupBySeverity } from 'ee/security_dashboard/store/modules/security_status/utils';

// eslint-disable-next-line import/prefer-default-export
export const severityGroups = ({ projects }) => groupBySeverity(projects);
