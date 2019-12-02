<script>
export default {
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    contentMaxHeight: {
      type: String,
      required: false,
      default: 'auto',
    },
  },
  created() {
    this.addRootInstanceEventListeners();
  },
  methods: {
    addRootInstanceEventListeners() {
      this.$root.$on('toggle', this.closeAllOtherChildren);
    },
    closeAllOtherChildren(eventTrigger) {
      this.$children.forEach(child => {
        if (child !== eventTrigger) {
          child.collapse();
        }
      });
    },
  },
};
</script>

<template>
  <div>
    <ul class="list-group list-group-flush py-2">
      <slot name="default"></slot>
    </ul>
  </div>
</template>
