import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Api from 'ee/api';
import * as cycleAnalyticsConstants from 'ee/analytics/cycle_analytics/constants';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  const mockEpics = [
    {
      id: 1,
      iid: 10,
      group_id: 2,
      title: 'foo',
    },
    {
      id: 2,
      iid: 11,
      group_id: 2,
      title: 'bar',
    },
  ];

  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = Object.assign({}, dummyGon);
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('ldapGroups', () => {
    it('calls callback on completion', done => {
      const query = 'query';
      const provider = 'provider';
      const callback = jasmine.createSpy();
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/ldap/${provider}/groups.json`;

      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.ldapGroups(query, provider, callback)
        .then(response => {
          expect(callback).toHaveBeenCalledWith(response);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('createChildEpic', () => {
    it('calls `axios.post` using params `groupId`, `parentEpicIid` and title', done => {
      const groupId = 'gitlab-org';
      const parentEpicIid = 1;
      const title = 'Sample epic';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${parentEpicIid}/epics`;
      const expectedRes = {
        title,
        id: 20,
        iid: 5,
      };

      mock.onPost(expectedUrl).reply(200, expectedRes);

      Api.createChildEpic({ groupId, parentEpicIid, title })
        .then(({ data }) => {
          expect(data.title).toBe(expectedRes.title);
          expect(data.id).toBe(expectedRes.id);
          expect(data.iid).toBe(expectedRes.iid);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('groupEpics', () => {
    it('calls `axios.get` using param `groupId`', done => {
      const groupId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics?include_ancestor_groups=false&include_descendant_groups=true`;

      mock.onGet(expectedUrl).reply(200, mockEpics);

      Api.groupEpics({ groupId })
        .then(({ data }) => {
          data.forEach((epic, index) => {
            expect(epic.id).toBe(mockEpics[index].id);
            expect(epic.iid).toBe(mockEpics[index].iid);
            expect(epic.group_id).toBe(mockEpics[index].group_id);
            expect(epic.title).toBe(mockEpics[index].title);
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('addEpicIssue', () => {
    it('calls `axios.post` using params `groupId`, `epicIid` and `issueId`', done => {
      const groupId = 2;
      const mockIssue = {
        id: 20,
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${mockEpics[0].iid}/issues/${mockIssue.id}`;
      const expectedRes = {
        id: 30,
        epic: mockEpics[0],
        issue: mockIssue,
      };

      mock.onPost(expectedUrl).reply(200, expectedRes);

      Api.addEpicIssue({ groupId, epicIid: mockEpics[0].iid, issueId: mockIssue.id })
        .then(({ data }) => {
          expect(data.id).toBe(expectedRes.id);
          expect(data.epic).toEqual(expect.objectContaining({ ...expectedRes.epic }));
          expect(data.issue).toEqual(expect.objectContaining({ ...expectedRes.issue }));
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('removeEpicIssue', () => {
    it('calls `axios.delete` using params `groupId`, `epicIid` and `epicIssueId`', done => {
      const groupId = 2;
      const mockIssue = {
        id: 20,
        epic_issue_id: 40,
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${mockEpics[0].iid}/issues/${mockIssue.epic_issue_id}`;
      const expectedRes = {
        id: 30,
        epic: mockEpics[0],
        issue: mockIssue,
      };

      mock.onDelete(expectedUrl).reply(200, expectedRes);

      Api.removeEpicIssue({
        groupId,
        epicIid: mockEpics[0].iid,
        epicIssueId: mockIssue.epic_issue_id,
      })
        .then(({ data }) => {
          expect(data.id).toBe(expectedRes.id);
          expect(data.epic).toEqual(expect.objectContaining({ ...expectedRes.epic }));
          expect(data.issue).toEqual(expect.objectContaining({ ...expectedRes.issue }));
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('getPodLogs', () => {
    const projectPath = 'root/test-project';
    const environmentId = 2;
    const podName = 'pod';
    const containerName = 'container';

    const lastUrl = () => mock.history.get[0].url;

    beforeEach(() => {
      mock.onAny().reply(200);
    });

    afterEach(() => {
      mock.reset();
    });

    it('calls `axios.get` with pod_name and container_name', done => {
      const expectedUrl = `${dummyUrlRoot}/${projectPath}/environments/${environmentId}/pods/${podName}/containers/${containerName}/logs.json`;

      Api.getPodLogs({ projectPath, environmentId, podName, containerName })
        .then(() => {
          expect(expectedUrl).toBe(lastUrl());
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls `axios.get` without pod_name and container_name', done => {
      const expectedUrl = `${dummyUrlRoot}/${projectPath}/environments/${environmentId}/pods/containers/logs.json`;

      Api.getPodLogs({ projectPath, environmentId })
        .then(() => {
          expect(expectedUrl).toBe(lastUrl());
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls `axios.get` with pod_name', done => {
      const expectedUrl = `${dummyUrlRoot}/${projectPath}/environments/${environmentId}/pods/${podName}/containers/logs.json`;

      Api.getPodLogs({ projectPath, environmentId, podName })
        .then(() => {
          expect(expectedUrl).toBe(lastUrl());
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('packages', () => {
    const projectId = 'project_a';
    const packageId = 'package_b';
    const apiResponse = [{ id: 1, name: 'foo' }];

    describe('groupPackages', () => {
      const groupId = 'group_a';

      it('fetch all group packages', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/packages`;
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(200, apiResponse);

        return Api.groupPackages(groupId).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, {});
        });
      });
    });

    describe('projectPackages', () => {
      it('fetch all project packages', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/packages`;
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(200, apiResponse);

        return Api.projectPackages(projectId).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, {});
        });
      });
    });

    describe('buildProjectPackageUrl', () => {
      it('returns the right url', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/packages/${packageId}`;
        const url = Api.buildProjectPackageUrl(projectId, packageId);
        expect(url).toEqual(expectedUrl);
      });
    });

    describe('projectPackage', () => {
      it('fetch package details', () => {
        const expectedUrl = `foo`;
        jest.spyOn(Api, 'buildProjectPackageUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(200, apiResponse);

        return Api.projectPackage(projectId, packageId).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl);
        });
      });
    });

    describe('deleteProjectPackage', () => {
      it('delete a package', () => {
        const expectedUrl = `foo`;

        jest.spyOn(Api, 'buildProjectPackageUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'delete');
        mock.onDelete(expectedUrl).replyOnce(200, true);

        return Api.deleteProjectPackage(projectId, packageId).then(({ data }) => {
          expect(data).toEqual(true);
          expect(axios.delete).toHaveBeenCalledWith(expectedUrl);
        });
      });
    });
  });

  describe('Cycle analytics', () => {
    const groupId = 'counting-54321';
    const createdBefore = '2019-11-18';
    const createdAfter = '2019-08-18';

    describe('cycleAnalyticsTasksByType', () => {
      it('fetches tasks by type data', done => {
        const tasksByTypeResponse = [
          {
            label: {
              id: 9,
              title: 'Thursday',
              color: '#7F8C8D',
              description: 'What are you waiting for?',
              group_id: 2,
              project_id: null,
              template: false,
              text_color: '#FFFFFF',
              created_at: '2019-08-20T05:22:49.046Z',
              updated_at: '2019-08-20T05:22:49.046Z',
            },
            series: [['2019-11-03', 5]],
          },
        ];
        const labelIds = [10, 9, 8, 7];
        const params = {
          group_id: groupId,
          created_after: createdAfter,
          created_before: createdBefore,
          project_ids: null,
          subject: cycleAnalyticsConstants.TASKS_BY_TYPE_SUBJECT_ISSUE,
          label_ids: labelIds,
        };
        const expectedUrl = `${dummyUrlRoot}/-/analytics/type_of_work/tasks_by_type`;
        mock.onGet(expectedUrl).reply(200, tasksByTypeResponse);

        Api.cycleAnalyticsTasksByType({ params })
          .then(({ data, config: { params: reqParams } }) => {
            expect(data).toEqual(tasksByTypeResponse);
            expect(reqParams.params).toEqual(params);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
