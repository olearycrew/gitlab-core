<script>
import { uniqueId } from 'underscore';
import { GlSkeletonLoader } from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';

const accordionUniqueId = name => uniqueId(`gl-accordion-${name}-`);

export default {
  inject: ['contentMaxHeight', 'isLoading'],
  components: {
    GlSkeletonLoader,
    Icon,
  },
  props: {
    onToggle: {
      type: Function,
      required: false,
      default: () => {},
    },
    maxHeight: {
      type: String,
      required: false,
      default() {
        return this.contentMaxHeight();
      },
    },
  },
  data() {
    return {
      isExpanded: false,
    };
  },
  computed: {
    contentStyles() {
      return {
        maxHeight: this.maxHeight,
        overflow: 'auto',
      };
    },
    hasContent() {
      return this.$slots.default;
    },
    hasTitleSubheader() {
      return this.$slots.titleSubheader;
    },
  },
  created() {
    this.buttonId = accordionUniqueId('trigger');
    this.contentId = accordionUniqueId('content');
  },
  methods: {
    handleClick() {
      this.isExpanded = !this.isExpanded;
      this.$root.$emit('toggle', this);
    },
  },
};
</script>

<template>
  <li class="list-group-item p-0">
    <template v-if="!isLoading()">
      <div class="d-flex align-items-stretch" :class="{ 'bg-warning': !hasContent }">
        <button
          ref="expansionTrigger"
          :id="buttonId"
          type="button"
          :aria-expanded="isExpanded"
          :aria-controls="contentId"
          class="btn border-0 rounded-0 w-100 p-0 text-left"
          @click="handleClick"
        >
          <div class="d-flex align-items-center p-2">
            <icon :size="16" class="mr-2" :name="isExpanded ? 'angle-down' : 'angle-right'" />
            <span><slot name="title" :is-expanded="isExpanded"></slot></span>
          </div>
          <div v-if="hasTitleSubheader" v-show="isExpanded" class="pl-5 pb-2">
            <slot name="titleSubheader"></slot>
          </div>
        </button>
      </div>
      <div
        v-show="isExpanded"
        ref="content"
        :id="contentId"
        :aria-labelledby="buttonId"
        class="py-2"
        :style="contentStyles"
        role="region"
      >
        <slot name="default"></slot>
      </div>
    </template>
    <div v-else ref="loadingIndicator" class="d-flex p-2">
      <div class="h-32-px">
        <gl-skeleton-loader :height="32">
          <rect width="12" height="16" rx="4" x="0" y="8" />
          <circle cx="37" cy="15" r="15" />
          <rect width="86" height="16" rx="4" x="63" y="8" />
        </gl-skeleton-loader>
      </div>
    </div>
  </li>
</template>
