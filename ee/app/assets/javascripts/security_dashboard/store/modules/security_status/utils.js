import {
  severityLevels,
  vulnerabilityTypes,
} from 'ee/security_dashboard/store/modules/security_status/contstants';

/**
 * Takes an array of severity levels and returns an object with each
 * severity level as keys and a `projects` property containing an empty array
 *
 * e.g,:
 *
 * {
 *   A: { projects: [] },
 *   B: { projects: [] },
 *   ...
 * }
 *
 * @param severityLevels
 * @returns {Object}
 */
export const getSeverityGroups = severityLevels =>
  Object.values(severityLevels).reduce(
    (groupProjects, levelName) => ({
      ...groupProjects,
      [levelName]: {
        projects: [],
      },
    }),
    {},
  );

/**
 * Takes a string `type` and a project containing vulnerability-count properties
 * and returns the count for the given type
 *
 * e.g,:
 * -> type = 'critical'; project = { critical_vulnerability_count: 99} => 99
 *
 * @param type
 * @param project
 * @returns {*}
 */
export const getVulnerabilityCount = (type, project) => project[`${type}_vulnerability_count`];

/**
 * Checks if a given project has zero vulnerability counts
 *
 * @param project
 * @returns {boolean}
 */
export const hasZeroVulnerabilities = project =>
  Object.values(vulnerabilityTypes).every(type => getVulnerabilityCount(type, project) === 0);

/**
 * Takes on ore more vulnerability types and returns a function that accepts a project
 * and returns if that project contains any vulnerabilities of the given levels
 *
 * @param types
 * @returns {function(*=): boolean}
 */
const hasVulnerabilitiesForType = (...types) => project =>
  types.some(type => getVulnerabilityCount(type, project) > 0);

/**
 * Maps each severity level to a function that returns if the given
 * project matches the given severity level's criteria
 *
 * @type {{[p: string]: function(*=): boolean}}
 */
export const projectsToSeverityLevel = {
  [severityLevels.A]: hasZeroVulnerabilities,
  [severityLevels.B]: hasVulnerabilitiesForType(vulnerabilityTypes.LOW),
  [severityLevels.D]: hasVulnerabilitiesForType(vulnerabilityTypes.MEDIUM),
  [severityLevels.E]: hasVulnerabilitiesForType(
    vulnerabilityTypes.HIGH,
    vulnerabilityTypes.UNKNOWN,
  ),
  [severityLevels.F]: hasVulnerabilitiesForType(vulnerabilityTypes.CRITICAL),
};

// @TODO - test and docblock
export const getMostSevereVulnerabilityType = project => {
  const vulnerabilityTypesBySeverityOrder = [
    vulnerabilityTypes.CRITICAL,
    vulnerabilityTypes.HIGH,
    vulnerabilityTypes.UNKNOWN,
    vulnerabilityTypes.MEDIUM,
    vulnerabilityTypes.LOW,
  ];

  // go through vulnerability types and check if current project has any
  for (let i = 0; i < vulnerabilityTypesBySeverityOrder.length; i += 1) {
    const currentTypeToCheck = vulnerabilityTypesBySeverityOrder[i];
    if (hasVulnerabilitiesForType(currentTypeToCheck)(project)) {
      return currentTypeToCheck;
    }
  }

  return '';
};

// @TODO - test and docblock
export const getMostSevereVulnerabilityCount = project => {
  const type = getMostSevereVulnerabilityType(project);
  // @TODO move this to function and check if we got something
  const count = project[`${type}_vulnerability_count`];

  return { type, count };
};

/**
 * Takes a project containing vulnerability counts and returns
 * the severity level it falls under
 *
 * @param project
 * @returns {string|*}
 */
export const getSeverityLevelForProject = project => {
  // order is important here - if for example the check for `severityLevel.F` is a match
  // there is no need to go further down the list
  const levelsToCheckInOrder = [
    severityLevels.F,
    severityLevels.E,
    severityLevels.D,
    severityLevels.B,
    severityLevels.A,
  ];

  for (let i = 0; i < levelsToCheckInOrder.length; i += 1) {
    const currentLevelToCheck = levelsToCheckInOrder[i];
    if (projectsToSeverityLevel[currentLevelToCheck](project)) {
      return currentLevelToCheck;
    }
  }

  return '';
};

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
export const groupBySeverityLevels = projects =>
  projects.reduce((groups, project) => {
    const groupForProject = groups[getSeverityLevelForProject(project)];

    if (groupForProject) {
      groups[getSeverityLevelForProject(project)].projects.push({
        ...project,
        mostCritical: {
          ...getMostSevereVulnerabilityCount(project),
        },
      });
    }

    return groups;
  }, getSeverityGroups(severityLevels));
