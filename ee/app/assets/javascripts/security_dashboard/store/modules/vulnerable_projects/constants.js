import { __ } from '~/locale';

export const SEVERITY_GROUP_TYPES = {
  F: 'F',
  D: 'D',
  C: 'C',
  B: 'B',
  A: 'A',
};

export const SEVERITY_LEVEL_TYPES = {
  critical: 'critical',
  high: 'high',
  unknown: 'unknown',
  medium: 'medium',
  low: 'low',
  none: 'none',
};

export const vulnerabilityTypesOrderedBySeverity = [
  {
    type: SEVERITY_LEVEL_TYPES.critical,
    name: __('critical'),
  },
  {
    type: SEVERITY_LEVEL_TYPES.high,
    name: __('high'),
  },
  {
    type: SEVERITY_LEVEL_TYPES.unknown,
    name: __('unknown'),
  },
  {
    type: SEVERITY_LEVEL_TYPES.medium,
    name: __('medium'),
  },
  {
    type: SEVERITY_LEVEL_TYPES.low,
    name: __('low'),
  },
  {
    type: SEVERITY_LEVEL_TYPES.none,
    name: __('none'),
  },
];

export const severityGroups = [
  {
    type: SEVERITY_GROUP_TYPES.F,
    name: __('F'),
    description: __('Projects with critical vulnerabilities'),
    warning: __('Critical vulnerabilities present'),
    severityLevelsIncluded: [SEVERITY_LEVEL_TYPES.critical],
  },
  {
    type: SEVERITY_GROUP_TYPES.D,
    name: __('D'),
    description: __('Projects with high or unknown vulnerabilities'),
    warning: __('High or unknown vulnerabilities present'),
    severityLevelsIncluded: [SEVERITY_LEVEL_TYPES.high, SEVERITY_LEVEL_TYPES.unknown],
  },
  {
    type: SEVERITY_GROUP_TYPES.C,
    name: __('C'),
    description: __('Projects with medium vulnerabilities'),
    warning: __('Medium vulnerabilities present'),
    severityLevelsIncluded: [SEVERITY_LEVEL_TYPES.medium],
  },
  {
    type: SEVERITY_GROUP_TYPES.B,
    name: __('B'),
    description: __('Projects with low vulnerabilities'),
    warning: __('Low vulnerabilities present'),
    severityLevelsIncluded: [SEVERITY_LEVEL_TYPES.low],
  },
  {
    type: SEVERITY_GROUP_TYPES.A,
    name: __('A'),
    description: __('Projects with no vulnerabilities and security scanning enabled'),
    warning: __('No vulnerabilities present'),
    severityLevelsIncluded: [SEVERITY_LEVEL_TYPES.none],
  },
];
