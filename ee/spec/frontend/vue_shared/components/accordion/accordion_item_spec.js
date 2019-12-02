import { shallowMount, createLocalVue, createWrapper } from '@vue/test-utils';
import { uniqueId } from 'underscore';

import { AccordionItem } from 'ee/vue_shared/components/accordion';

jest.mock('underscore', () => ({
  uniqueId: jest.fn().mockReturnValue('mockUniqueId'),
}));

const localVue = createLocalVue();

describe('AccordionItem component', () => {
  let wrapper;

  const factory = ({ propsData = {}, defaultSlot = `<p></p>`, titleSlot = `<p></p>` } = {}) => {
    wrapper = shallowMount(AccordionItem, {
      localVue,
      sync: false,
      propsData,
      scopedSlots: {
        default: defaultSlot,
        title: titleSlot,
      },
    });
  };

  const contentContainer = () => wrapper.find({ ref: 'content' });
  const expansionTrigger = () => wrapper.find({ ref: 'expansionTrigger' });
  const loadingIndicator = () => wrapper.find({ ref: 'loadingIndicator' });

  afterEach(() => {
    wrapper.destroy();
    jest.restoreAllMocks();
  });

  describe('rendering options', () => {
    beforeEach(factory);

    it('does not show a loading indicator per default', () => {
      expect(loadingIndicator().exists()).toBe(false);
    });

    it('shows a loading indicator if the "isLoading" prop is set to "true"', () => {
      wrapper.setProps({ isLoading: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(loadingIndicator().exists()).toBe(true);
      });
    });

    it('does not limit the content height per default', () => {
      expect(contentContainer().element.style.maxHeight).toBeFalsy();
    });

    it('limits the content height to the injected "contentMaxHeight" value', () => {
      wrapper.setProps({ maxHeight: '200px' });

      return wrapper.vm.$nextTick().then(() => {
        expect(contentContainer().element.style.maxHeight).toBe('200px');
      });
    });
  });

  describe('scoped slots', () => {
    it.each(['default', 'title'])("contains a '%s' slot", slotName => {
      const className = `${slotName}-slot-content`;

      factory({ [`${slotName}Slot`]: `<div class='${className}' />` });

      expect(wrapper.find(`.${className}`).exists()).toBe(true);
    });

    it('contains a default slot', () => {
      factory({ defaultSlot: `<div class='foo' />` });
      expect(wrapper.find(`.foo`).exists()).toBe(true);
    });

    it.each([true, false])(
      'passes the "isExpanded" and "isDisabled" state to the title slot',
      state => {
        const titleSlot = jest.fn();

        factory({ propsData: { disabled: state }, titleSlot });
        wrapper.vm.isExpanded = state;

        return wrapper.vm.$nextTick().then(() => {
          expect(titleSlot).toHaveBeenCalledWith({
            isExpanded: state,
            isDisabled: state,
          });
        });
      },
    );
  });

  describe('collapsing and expanding', () => {
    beforeEach(factory);

    it('is collapsed per default', () => {
      expect(contentContainer().isVisible()).toBe(false);
    });

    it('expands when the trigger-element gets clicked', () => {
      expect(contentContainer().isVisible()).toBe(false);

      expansionTrigger().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(contentContainer().isVisible()).toBe(true);
      });
    });

    it('emits a "toggle" event containing the trigger item as a payload', () => {
      expansionTrigger().trigger('click');

      const rootWrapper = createWrapper(wrapper.vm.$root);

      expect(rootWrapper.emitted('toggle').length).toBe(1);
      expect(rootWrapper.emitted('toggle')[0][0]).toEqual(wrapper.vm);
    });

    it('contains a collapse method that collapses', () => {
      wrapper.setData({ isExpanded: true });

      wrapper.vm.collapse();

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.isExpanded).toBe(false);
      });
    });
  });

  describe('accessibility', () => {
    beforeEach(factory);

    it('contains a expansion trigger element with a unique, namespaced id', () => {
      expect(uniqueId).toHaveBeenCalledWith('gl-accordion-trigger-');

      expect(expansionTrigger().attributes('id')).toBe('mockUniqueId');
    });

    it('contains a expansion trigger element with a unique, namespaced id', () => {
      expect(uniqueId).toHaveBeenCalledWith('gl-accordion-content-');
      expect(contentContainer().attributes('id')).toBe('mockUniqueId');
    });

    it('has a trigger element that has an "aria-expanded" attribute set, to show if it is expanded or collapsed', () => {
      expect(expansionTrigger().attributes('aria-expanded')).toBeFalsy();

      wrapper.setData({ isExpanded: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(expansionTrigger().attributes('aria-expanded')).toBe('true');
      });
    });

    it('has a trigger element that has a "aria-controls" attribute, which points to the content element', () => {
      expect(expansionTrigger().attributes('aria-controls')).toBeTruthy();
      expect(expansionTrigger().attributes('aria-controls')).toBe(
        contentContainer().attributes('id'),
      );
    });

    it('has a content element that has a "aria-labelledby" attribute, which points to the trigger element', () => {
      expect(contentContainer().attributes('aria-labelledby')).toBeTruthy();
      expect(contentContainer().attributes('aria-labelledby')).toBe(
        expansionTrigger().attributes('id'),
      );
    });
  });
});
