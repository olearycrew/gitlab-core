import axios from 'axios';

import { groupBySeverityLevels, getMostSevereVulnerabilityType } from './utils';

// @TODO - break this into files
const severityLevels = {
  namespaced: true,
  state: {
    isLoading: '',
    hasError: '',
    projects: [],
  },
  mutations: {
    setLoading(state, isLoading) {
      state.isLoading = isLoading;
    },
    setProjects(state, projects) {
      state.projects = projects;
    },
    setHasError(state, hasError) {
      state.hasError = hasError;
    },
  },
  actions: {
    fetchProjects({ dispatch }, endpoint) {
      dispatch('request');

      return axios
        .get(endpoint)
        .then(({ data }) => {
          dispatch('receiveSuccess', data);
        })
        .catch(() => {
          dispatch('receiveError');
        });
    },
    request({ commit }) {
      commit('setLoading', true);
      commit('setHasError', false);
    },
    receiveSuccess({ commit }, payload) {
      commit('setLoading', false);
      commit('setProjects', payload);
    },
    receiveError({ commit }) {
      commit('setHasError', true);
    },
  },
  getters: {
    projectsBySeverityLevels: ({ projects }) => groupBySeverityLevels(projects),
    mostSevereVulnerabilityCount: () => projectToCheck =>
      getMostSevereVulnerabilityType(projectToCheck),
  },
};

export default severityLevels;
