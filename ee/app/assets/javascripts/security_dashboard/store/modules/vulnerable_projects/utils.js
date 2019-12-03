import {
  severityGroups,
  vulnerabilityTypesOrderedBySeverity,
} from 'ee/security_dashboard/store/modules/vulnerable_projects/constants';

/**
 * Takes a string (type) and a project-object containing vulnerability-count properties
 * and returns the count for the given type
 *
 * e.g,:
 * -> type = 'critical'; project = { critical_vulnerability_count: 99} => 99
 *
 * @param type {String}
 * @param project {Object}
 * @returns {*}
 */

/**
 * Takes a string (type) and a project-object containing vulnerability-count properties
 * and returns the count for the given type
 *
 * e.g,:
 * -> type = 'critical'; project = { critical_vulnerability_count: 99} => 99
 *
 * @param type
 * @param project
 * @returns {*|null}
 */
export const getVulnerabilityCount = (type, project) =>
  project[`${type}_vulnerability_count`] || null;

/**
 * Takes a project and returns its most severe vulnerability type
 *
 * @param project {Object}
 * @returns {{type, name}|*}
 */
export const getMostSevereVulnerabilityType = project => {
  const typesCount = vulnerabilityTypesOrderedBySeverity.length;
  for (let i = 0; i < typesCount; i += 1) {
    const typeToCheck = vulnerabilityTypesOrderedBySeverity[i];

    if (getVulnerabilityCount(typeToCheck.type, project) > 0) {
      return typeToCheck;
    }
  }

  // the last element is of type 'none'
  return vulnerabilityTypesOrderedBySeverity[typesCount - 1];
};

/**
 * Takes a severity type and returns the severity group it falls under
 *
 * @param groups
 * @param type
 * @returns {*|null}
 */
export const getSeverityGroupForType = (groups, type) =>
  groups.find(group => group.severityLevelsIncluded.includes(type)) || null;

/**
 * Generates an object containing all defined severity groups
 *
 * @param groups {Array}
 * @returns {*}
 */
export const getSeverityGroupsData = groups =>
  groups.reduce(
    (groupsData, { type, name, description, warning }) => ({
      ...groupsData,
      [type]: {
        name,
        description,
        warning,
        projects: [],
      },
    }),
    {},
  );

/**
 * Takes a project and the type of its most severe vulnerability.
 * Transforms properties into camelcase and adds a property that contains
 * the type and count of its most sever vulnerability type
 *
 * @param project {Object}
 * @param mostSevereVulnerabilityType {String}
 * @returns {{path: *, mostSevere: {name: *, count: *}, name: *, id: *}}
 */
export const getProjectData = (project, { type, name }) => ({
  id: project.id,
  name: project.full_name,
  path: project.full_path,
  mostSevere: {
    name,
    count: getVulnerabilityCount(type, project),
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
 * @returns {Array}
 */
export const groupBySeverityLevel = projects => {
  const severityGroupsMap = projects.reduce((groups, project) => {
    const mostSevereVulnerabilityType = getMostSevereVulnerabilityType(project);
    const severityGroup = getSeverityGroupForType(severityGroups, mostSevereVulnerabilityType.type);

    if (!severityGroup) {
      return groups;
    }

    groups[severityGroup.type].projects.push(getProjectData(project, mostSevereVulnerabilityType));

    return groups;
  }, getSeverityGroupsData(severityGroups));

  return Object.values(severityGroupsMap);
};
