import { __ } from '~/locale';

export const SEVERITY_LEVELS = {
  A: 'A',
  B: 'B',
  D: 'D',
  E: 'E',
  F: 'F',
};

export const VULNERABILITY_TYPES = {
  critical: 'critical',
  high: 'high',
  unknown: 'unknown',
  medium: 'medium',
  low: 'low',
  none: 'none',
};

export const vulnerabilityTypesOrderedBySeverity = [
  {
    name: VULNERABILITY_TYPES.critical,
    displayName: __('critical'),
  },
  {
    name: VULNERABILITY_TYPES.high,
    displayName: __('high'),
  },
  {
    name: VULNERABILITY_TYPES.unknown,
    displayName: __('unknown'),
  },
  {
    name: VULNERABILITY_TYPES.medium,
    displayName: __('medium'),
  },
  {
    name: VULNERABILITY_TYPES.low,
    displayName: __('low'),
  },
  {
    name: VULNERABILITY_TYPES.none,
    displayName: __('none'),
  },
];

export const severityGroups = [
  {
    name: SEVERITY_LEVELS.F,
    displayName: __('F'),
    description: __('Some description for F'),
    vulnerabilityTypes: [VULNERABILITY_TYPES.critical],
  },
  {
    name: SEVERITY_LEVELS.E,
    displayName: __('E'),
    description: __('Some description for E'),
    vulnerabilityTypes: [VULNERABILITY_TYPES.high, VULNERABILITY_TYPES.unknown],
  },
  {
    name: SEVERITY_LEVELS.D,
    displayName: __('D'),
    description: __('Some description for D'),
    vulnerabilityTypes: [VULNERABILITY_TYPES.medium],
  },
  {
    name: SEVERITY_LEVELS.B,
    displayName: __('B'),
    description: __('Some description for B'),
    vulnerabilityTypes: [VULNERABILITY_TYPES.low],
  },
  {
    name: SEVERITY_LEVELS.A,
    displayName: __('A'),
    description: __('Some description for A'),
    vulnerabilityTypes: [VULNERABILITY_TYPES.none],
  },
];
