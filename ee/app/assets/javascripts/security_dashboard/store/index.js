import Vue from 'vue';
import Vuex from 'vuex';
import mediator from './plugins/mediator';

import filters from './modules/filters/index';
import vulnerabilities from './modules/vulnerabilities/index';
import securityStatus from './modules/security_status/index';

Vue.use(Vuex);

export default ({ plugins = [] } = {}) =>
  new Vuex.Store({
    modules: {
      securityStatus,
      filters,
      vulnerabilities,
    },
    plugins: [mediator, ...plugins],
  });
