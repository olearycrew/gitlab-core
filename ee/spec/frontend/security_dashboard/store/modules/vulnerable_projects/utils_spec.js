import {
  getMostSevereVulnerabilityType,
  getProjectData,
  getSeverityGroupForType,
  getSeverityGroupsData,
  getVulnerabilityCount,
  groupBySeverityLevel,
} from 'ee/security_dashboard/store/modules/vulnerable_projects/utils';

const createMockProjectWithZeroVulnerabilities = () => ({
  id: 'id',
  full_name: 'full_name',
  full_path: 'full_path',
  critical_vulnerability_count: 0,
  high_vulnerability_count: 0,
  medium_vulnerability_count: 0,
  low_vulnerability_count: 0,
  unknown_vulnerability_count: 0,
});

const createMockProjectWithVulnerabilities = (count = 1) => (...vulnerabilityLevels) => ({
  ...createMockProjectWithZeroVulnerabilities(),
  ...(vulnerabilityLevels
    ? vulnerabilityLevels.reduce(
        (levels, level) => ({
          ...levels,
          [`${level}_vulnerability_count`]: count,
        }),
        {},
      )
    : {}),
});

const createMockProjectWithOneVulnerability = createMockProjectWithVulnerabilities(1);

describe('SeverityLevels store utils', () => {
  describe('getMostSevereVulnerabilityType', () => {
    it.each`
      vulnerabilityTypesInProject                         | expectedType  | expectedName
      ${['critical', 'high', 'unknown', 'medium', 'low']} | ${'critical'} | ${'critical'}
      ${['high', 'unknown', 'medium', 'low']}             | ${'high'}     | ${'high'}
      ${['unknown', 'medium', 'low']}                     | ${'unknown'}  | ${'unknown'}
      ${['medium', 'low']}                                | ${'medium'}   | ${'medium'}
      ${['low']}                                          | ${'low'}      | ${'low'}
      ${[]}                                               | ${'none'}     | ${'none'}
    `(
      'given $vulnerabilityTypesInProject returns an object containing the name and type of the most severe vulnerability',
      ({ vulnerabilityTypesInProject, expectedType, expectedName }) => {
        const mockProject = createMockProjectWithOneVulnerability(...vulnerabilityTypesInProject);

        expect(getMostSevereVulnerabilityType(mockProject)).toEqual({
          name: expectedType,
          type: expectedName,
        });
      },
    );
  });

  describe('getProjectData', () => {
    it('takes a project and its most severe vulnerability type and returns the data used to render the project', () => {
      expect(
        getProjectData(createMockProjectWithZeroVulnerabilities(), {
          displayName: 'foo',
          name: 'bar',
        }),
      ).toMatchSnapshot();
    });
  });

  describe('getSeverityGroupForType', () => {
    it.each`
      vulnerabilityType | expectedSeverityGroup
      ${'critical'}     | ${'F'}
      ${'high'}         | ${'D'}
      ${'unknown'}      | ${'D'}
      ${'medium'}       | ${'C'}
      ${'low'}          | ${'B'}
      ${'none'}         | ${'A'}
    `(
      'returns $expectedSeverityGroup for the given $vulnerabilityType',
      ({ vulnerabilityType, expectedSeverityGroup }) => {
        expect(getSeverityGroupForType(vulnerabilityType).name).toBe(expectedSeverityGroup);
      },
    );
  });

  describe('getSeverityGroupsData', () => {
    it("returns a map with the given severity levels containing an empty 'projects' array", () => {
      const severityGroups = [
        {
          type: 'foo',
          name: 'fooName',
          description: 'fooDescription',
          warning: 'fooWarning',
        },
        {
          type: 'bar',
          name: 'barName',
          description: 'barDescription',
          warning: 'barWarning',
        },
      ];

      expect(getSeverityGroupsData(severityGroups)).toStrictEqual({
        foo: {
          name: 'fooName',
          description: 'fooDescription',
          warning: 'fooWarning',
          projects: [],
        },
        bar: {
          name: 'barName',
          description: 'barDescription',
          warning: 'barWarning',
          projects: [],
        },
      });
    });
  });

  describe('getVulnerabilityCount', () => {
    it.each`
      vulnerabilityType | vulnerabilityCount
      ${'critical'}     | ${1}
      ${'high'}         | ${2}
      ${'medium'}       | ${3}
      ${'low'}          | ${4}
      ${'unknown'}      | ${5}
    `(
      "returns the correct count for '$vulnerabilityType' vulnerabilities",
      ({ vulnerabilityType, vulnerabilityCount }) => {
        const project = createMockProjectWithVulnerabilities(vulnerabilityCount)(vulnerabilityType);

        expect(getVulnerabilityCount(vulnerabilityType, project)).toBe(vulnerabilityCount);
      },
    );
  });

  describe('groupBySeverityLevel', () => {
    it('takes an array of projects containing vulnerability data and groups them by severity level', () => {
      const projectsWithVulnerabilities = [
        createMockProjectWithOneVulnerability('critical'),
        createMockProjectWithOneVulnerability('high'),
        createMockProjectWithOneVulnerability('unknown'),
        createMockProjectWithOneVulnerability('medium'),
        createMockProjectWithOneVulnerability('low'),
        createMockProjectWithZeroVulnerabilities(),
      ];

      const projectsGroupedBySeverityLevel = groupBySeverityLevel(
        Object.values(projectsWithVulnerabilities),
      );

      expect(projectsGroupedBySeverityLevel).toMatchSnapshot();
    });
  });
});
