import axios from 'axios';

import { groupBySeverityLevels } from './utils';

const severityLevels = {
  namespaced: true,
  state: {
    endpoint: '',
    isLoading: '',
    hasError: '',
    projects: [],
  },
  mutations: {
    setEndpoint(state, url) {
      state.endpoint = url;
    },
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
    setEndpoint({ commit }, url) {
      commit('setEndpoint', url);
    },
    fetchProjects({ dispatch, state }) {
      dispatch('request');

      return axios
        .get(state.endpoint)
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
    projectsBySeverityLevels({ projects }) {
      return groupBySeverityLevels(projects);
    },
  },
};

export default severityLevels;
