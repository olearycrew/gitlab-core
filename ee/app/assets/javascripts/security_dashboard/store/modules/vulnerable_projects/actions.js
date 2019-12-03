import axios from 'axios';

import { SET_LOADING, SET_PROJECTS, SET_HAS_ERRORS } from './mutation_types';

export const fetchProjects = ({ dispatch }, endpoint) => {
  dispatch('requestProjects');

  return axios
    .get(endpoint)
    .then(({ data }) => {
      dispatch('receiveProjectsSuccess', data);
    })
    .catch(() => {
      dispatch('receiveProjectsError');
    });
};

export const requestProjects = ({ commit }) => {
  commit(SET_LOADING, true);
  commit(SET_HAS_ERRORS, false);
};

export const receiveProjectsSuccess = ({ commit }, payload) => {
  commit(SET_LOADING, false);
  commit(SET_PROJECTS, payload);
};

export const receiveProjectsError = ({ commit }) => {
  commit(SET_HAS_ERRORS, true);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-foss#52179 is merged
export default () => {};
