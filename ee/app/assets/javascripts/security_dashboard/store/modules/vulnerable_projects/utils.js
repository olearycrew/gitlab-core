import {
  severityGroups,
  SEVERITY_LEVEL_TYPES,
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
export const getVulnerabilityCount = (type, project) => project[`${type}_vulnerability_count`];

/**
 * Takes a project and returns the its most severe vulnerability type
 *
 * @param project {Object}
 * @returns {{type, name}|*}
 */
export const getMostSevereVulnerabilityType = project => {
  for (let i = 0; i < vulnerabilityTypesOrderedBySeverity.length; i += 1) {
    const typeToCheck = vulnerabilityTypesOrderedBySeverity[i];

    if (getVulnerabilityCount(typeToCheck.type, project) > 0) {
      return typeToCheck;
    }
  }

  return vulnerabilityTypesOrderedBySeverity.find(({ type }) => type === SEVERITY_LEVEL_TYPES.none);
};

/**
 * Takes a severity type and returns the severity group it falls under
 *
 * @param type {String}
 * @returns {{type, name, description, vulnerabilityTypes}|*|null}
 */
export const getSeverityGroupForType = type => {
  for (let i = 0; i < severityGroups.length; i += 1) {
    const levelToCheck = severityGroups[i];

    if (levelToCheck.severityLevelsIncluded.includes(type)) {
      return levelToCheck;
    }
  }

  return null;
};

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
 * the the type and count of its most sever vulnerability type
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
  const groupsData = getSeverityGroupsData(severityGroups);

  projects.forEach(project => {
    const mostSevereVulnerabilityType = getMostSevereVulnerabilityType(project);
    const severityGroup = getSeverityGroupForType(mostSevereVulnerabilityType.type);

    if (!severityGroup) {
      return;
    }

    groupsData[severityGroup.type].projects.push(
      getProjectData(project, mostSevereVulnerabilityType),
    );
  });

  return Object.values(groupsData);
};
