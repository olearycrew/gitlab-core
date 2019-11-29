/**
 * All defined severity levels
 *
 *  A = 0 active vulnerabilities in a project known to have security tests set-up
 *  B = 1 or more low active vulnerability
 *  C = 1 or more medium active vulnerability
 *  D = 1 or more high or Unknown active vulnerabilities
 *  F = 1 or more critical active vulnerability
 *
 * @type {{A: string, B: string, D: string, E: string, F: string}}
 */
export const severityLevels = {
  A: 'A',
  B: 'B',
  D: 'D',
  E: 'E',
  F: 'F',
};

/**
 * Types of vulnerabilities
 *
 * @type {{HIGH: string, MEDIUM: string, LOW: string, UNKNOWN: string, CRITICAL: string}}
 */
export const vulnerabilityTypes = {
  UNKNOWN: 'unknown',
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  CRITICAL: 'critical',
};
