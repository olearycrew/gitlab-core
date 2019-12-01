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

const vulnerabilityTypesOrderedBySeverity = [
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

const severityGroups = [
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

/**
 * Takes a string `type` and a project containing vulnerability-count properties
 * and returns the count for the given type
 *
 * e.g,:
 * -> type = 'critical'; project = { critical_vulnerability_count: 99} => 99
 *
 * @param name {String}
 * @param project {Object}
 * @returns {*}
 */
export const getVulnerabilityCount = (name, project) => project[`${name}_vulnerability_count`];

/**
 * Takes a project and returns the type of its most severe vulnerability
 *
 * @param project {Object}
 * @returns {{displayName, name}|*}
 */
export const getMostSevereVulnerabilityType = project => {
  for (let i = 0; i < vulnerabilityTypesOrderedBySeverity.length; i++) {
    const typeToCheck = vulnerabilityTypesOrderedBySeverity[i];

    if (getVulnerabilityCount(typeToCheck.name, project) > 0) {
      return typeToCheck;
    }
  }

  return vulnerabilityTypesOrderedBySeverity.find(type => type.name === VULNERABILITY_TYPES.none);
};

/**
 * Takes a severity type and returns the severity level it belongs to
 *
 * @param type {String}
 * @returns {{displayName, name, description, vulnerabilityTypes}|*|null}
 */
export const getSeverityGroupForType = type => {
  for (let i = 0; i < severityGroups.length; i++) {
    const levelToCheck = severityGroups[i];

    if (levelToCheck.vulnerabilityTypes.includes(type)) {
      return levelToCheck;
    }
  }

  return null;
};

/**
 * Generates an object containing all defined severity groups and the data
 * that the UI is interested in
 * @param severityLevels {Array}
 * @returns {*}
 */
export const getSeverityGroups = severityLevels => {
  const groups = new Map();

  severityLevels.forEach(({ name, displayName, description }) => {
    groups.set(name, {
      name: displayName,
      description,
      projects: [],
    });
  });

  return groups;
  // severityLevels.reduce(
  //   (groups, level) => ({
  //     ...groups,
  //     [level.name]: {
  //       name: level.displayName,
  //       description: level.description,
  //       projects: [],
  //     },
  //   }),
  //   {},
  // );
};

/**
 * Takes a project and the type of its most severe vulnerability.
 * Returns * an object containing all the data the UI is interested in
 *
 * @param project {Object}
 * @param mostSevereVulnerabilityType {String}
 * @returns {{path: *, mostSevere: {name: *, count: *}, name: *, id: *}}
 */
export const getProjectData = (project, { displayName, name }) => ({
  id: project.id,
  name: project.full_name,
  path: project.full_path,
  mostSevere: {
    name: displayName,
    count: getVulnerabilityCount(name, project),
  },
});

/**
 * Takes an array of projects and returns an object containing
 * all severity levels as keys and and a `projects` array, which
 * holds all projects belonging to that level
 *
 * e.g,: -> {
 *   A: { projects: [{ project1 }, {project2}, ... ]}
 *   B: { projects: [{ project3 }, {project4}, ... ]}
 *   ...
 * }
 *
 * @param {Array} projects
 * @returns {*}
 */
export const groupBySeverity = projects => {
  const groups = getSeverityGroups(severityGroups);

  projects.forEach(project => {
    const mostSevereVulnerabilityType = getMostSevereVulnerabilityType(project);
    const severityGroup = getSeverityGroupForType(mostSevereVulnerabilityType.name);

    if (!severityGroup) {
      return;
    }

    groups
      .get(severityGroup.name)
      .projects.push(getProjectData(project, mostSevereVulnerabilityType));
  });

  return Array.from(groups.values());
};
