import {
  getMostSevereVulnerabilityType,
  getProjectData,
  getSeverityGroupForType,
  getSeverityGroups,
  getVulnerabilityCount,
  groupBySeverity,
} from 'ee/security_dashboard/store/modules/security_status/utils';

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
      vulnerabilityTypesInProject                         | expectedType
      ${['critical', 'high', 'unknown', 'medium', 'low']} | ${'critical'}
      ${['high', 'unknown', 'medium', 'low']}             | ${'high'}
      ${['unknown', 'medium', 'low']}                     | ${'unknown'}
      ${['medium', 'low']}                                | ${'medium'}
      ${['low']}                                          | ${'low'}
      ${[]}                                               | ${'none'}
    `(
      "given $vulnerabilityTypesInProject returns '$expectedType'",
      ({ vulnerabilityTypesInProject, expectedType }) => {
        const mockProject = createMockProjectWithOneVulnerability(...vulnerabilityTypesInProject);

        expect(getMostSevereVulnerabilityType(mockProject)).toEqual({
          displayName: expectedType,
          name: expectedType,
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
      ${'high'}         | ${'E'}
      ${'unknown'}      | ${'E'}
      ${'medium'}       | ${'D'}
      ${'low'}          | ${'B'}
      ${'none'}         | ${'A'}
    `(
      'returns $expectedSeverityGroup for the given $vulnerabilityType',
      ({ vulnerabilityType, expectedSeverityGroup }) => {
        expect(getSeverityGroupForType(vulnerabilityType).name).toBe(expectedSeverityGroup);
      },
    );
  });

  describe('getSeverityGroups', () => {
    it("returns a map with the given severity levels containing an empty 'projects' array", () => {
      const severityLevels = [
        {
          name: 'fooName',
          displayName: 'fooDisplayName',
          description: 'fooDescription',
        },
        {
          name: 'barName',
          displayName: 'barDisplayName',
          description: 'barDescription',
        },
      ];

      const groups = getSeverityGroups(severityLevels);

      expect(groups.get('fooName')).toStrictEqual({
        name: 'fooDisplayName',
        description: 'fooDescription',
        projects: [],
      });

      expect(groups.get('barName')).toStrictEqual({
        name: 'barDisplayName',
        description: 'barDescription',
        projects: [],
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

  describe('groupBySeverity', () => {
    it('takes an array of projects containing vulnerability data and groups them by severity level', () => {
      const projectsWithVulnerabilities = [
        createMockProjectWithOneVulnerability('critical'),
        createMockProjectWithOneVulnerability('high'),
        createMockProjectWithOneVulnerability('unknown'),
        createMockProjectWithOneVulnerability('medium'),
        createMockProjectWithOneVulnerability('low'),
        createMockProjectWithZeroVulnerabilities(),
      ];

      const projectsGroupedBySeverityLevel = groupBySeverity(
        Object.values(projectsWithVulnerabilities),
      );

      expect(projectsGroupedBySeverityLevel).toMatchSnapshot();
    });
  });
});
