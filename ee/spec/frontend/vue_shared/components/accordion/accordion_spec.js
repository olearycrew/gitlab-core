import { shallowMount, createLocalVue } from '@vue/test-utils';
import { Accordion } from 'ee/vue_shared/components/accordion';

const localVue = createLocalVue();

describe('Accordion component', () => {
  const mockAccordionItem = () => ({
    name: 'mock-accordion-item',
    render() {},
    data() {
      return { isExpanded: false };
    },
    methods: {
      collapse() {
        this.isExpanded = false;
      },
    },
  });

  const createMockAccordionItems = n => [...Array(n).keys()].map(mockAccordionItem);

  let wrapper;
  const factory = ({
    defaultSlot = createMockAccordionItems(3),
    contentMaxHeight = '',
    isLoading = false,
  } = {}) => {
    wrapper = shallowMount(Accordion, {
      localVue,
      sync: false,
      propsData: {
        contentMaxHeight,
        isLoading,
      },
      slots: {
        default: defaultSlot,
      },
    });
  };

  const accordionItems = () => wrapper.findAll(mockAccordionItem());

  beforeEach(factory);

  afterEach(() => {
    wrapper.destroy();
  });

  it.each([1, 3, 5])('contains %d given accordion-items', numberOfItems => {
    factory({ defaultSlot: createMockAccordionItems(numberOfItems) });

    expect(accordionItems().length).toBe(numberOfItems);
  });

  it.each`
    emittingChildIndex | childAtIndexZeroIsExpanded | childAtIndexOneIsExpanded | childAtIndexTwoIsExpanded
    ${0}               | ${true}                    | ${false}                  | ${false}
    ${1}               | ${false}                   | ${true}                   | ${false}
    ${2}               | ${false}                   | ${false}                  | ${true}
  `(
    "reacts to the 'toggle' event by closing all children, except the one that emits",
    ({
      emittingChildIndex,
      childAtIndexZeroIsExpanded,
      childAtIndexOneIsExpanded,
      childAtIndexTwoIsExpanded,
    }) => {
      const items = accordionItems();
      const emittingChild = items.at(emittingChildIndex).vm;

      const setExpanded = itemWrapper => itemWrapper.setData({ isExpanded: true });
      items.wrappers.forEach(setExpanded);

      wrapper.vm.$root.$emit('toggle', emittingChild);

      expect(items.at(0).vm.isExpanded).toBe(childAtIndexZeroIsExpanded);
      expect(items.at(1).vm.isExpanded).toBe(childAtIndexOneIsExpanded);
      expect(items.at(2).vm.isExpanded).toBe(childAtIndexTwoIsExpanded);
    },
  );
});
