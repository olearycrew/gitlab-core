import axios from 'axios';

import { SET_LOADING, SET_PROJECTS, SET_HAS_ERRORS } from './mutation_types';

export const fetchProjects = ({ dispatch }, endpoint) => {
  dispatch('request');

  return axios
    .get(endpoint)
    .then(({ data }) => {
      dispatch('receiveSuccess', data);
    })
    .catch(() => {
      dispatch('receiveError');
    });
};

export const request = ({ commit }) => {
  commit(SET_LOADING, true);
  commit(SET_HAS_ERRORS, false);
};

export const receiveSuccess = ({ commit }, payload) => {
  commit(SET_LOADING, false);
  commit(SET_PROJECTS, payload);
};

export const receiveError = ({ commit }) => {
  commit(SET_HAS_ERRORS, true);
};
