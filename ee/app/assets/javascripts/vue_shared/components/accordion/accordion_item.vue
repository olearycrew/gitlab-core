<script>
import { uniqueId } from 'underscore';
import { GlSkeletonLoader } from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';

const accordionUniqueId = name => uniqueId(`gl-accordion-${name}-`);

export default {
  components: {
    GlSkeletonLoader,
    Icon,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    onToggle: {
      type: Function,
      required: false,
      default: () => {},
    },
    maxHeight: {
      type: String,
      required: false,
      default() {
        return this.$parent.contentMaxHeight;
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
    isLoading() {
      return this.$parent.isLoading;
    },
    isDisabled() {
      return this.disabled || !this.hasContent;
    },
    hasContent() {
      return this.$slots.default;
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
    <template v-if="!isLoading">
      <div class="d-flex align-items-stretch" :class="{ 'bg-warning': !hasContent }">
        <button
          :id="buttonId"
          ref="expansionTrigger"
          :disabled="isDisabled"
          :readonly="isDisabled"
          type="button"
          :aria-expanded="isExpanded"
          :aria-controls="contentId"
          class="btn-transparent border-0 rounded-0 w-100 p-0 text-left"
          @click="handleClick"
        >
          <div
            class="d-flex align-items-center p-2"
            :class="{ 'list-group-item-action': !isDisabled }"
          >
            <icon :size="16" class="mr-2" :name="isExpanded ? 'angle-down' : 'angle-right'" />
            <span
              ><slot name="title" :is-expanded="isExpanded" :is-disabled="isDisabled"></slot
            ></span>
          </div>
        </button>
      </div>
      <div
        v-show="isExpanded"
        :id="contentId"
        ref="content"
        :aria-labelledby="buttonId"
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
          <rect width="20" height="16" rx="4" x="63" y="8" />
        </gl-skeleton-loader>
      </div>
    </div>
  </li>
</template>
