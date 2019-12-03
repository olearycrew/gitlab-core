# frozen_string_literal: true
module EE
  module HooksHelper
    extend ::Gitlab::Utils::Override

    def test_hook_path(hook, trigger)
      if hook.is_a?(GroupHook)
        test_group_hook_path(hook.group, hook, trigger: trigger)
      else
        super
      end
    end

    def edit_hook_path(hook)
      if hook.is_a?(GroupHook)
        edit_group_hook_path(hook.group, hook)
      else
        super
      end
    end

    def destroy_hook_path(hook)
      if hook.is_a?(GroupHook)
        group_hook_path(hook.group, hook)
      else
        super
      end
    end
  end
end
