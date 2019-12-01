import { SET_LOADING, SET_PROJECTS, SET_HAS_ERRORS } from './mutation_types';

export default {
  [SET_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },
  [SET_PROJECTS](state, projects) {
    state.projects = projects;
  },
  [SET_HAS_ERRORS](state, hasError) {
    state.hasError = hasError;
  },
};
