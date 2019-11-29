# frozen_string_literal: true

module HooksHelper
  def link_to_hook_docs(hook)
    case hook
    when SystemHook
      link_to _('System hooks'), help_page_path('system_hooks/system_hooks')
    else
      link_to _('Webhooks'), help_page_path('user/project/integrations/webhooks')
    end
  end

  def link_to_test_hook(hook, trigger)
    path = case hook
           when GroupHook
             test_group_hook_path(hook.group, hook, trigger: trigger)
           when ProjectHook
             project = hook.project
             test_project_hook_path(project, hook, trigger: trigger)
           when SystemHook
             test_admin_hook_path(hook, trigger: trigger)
           end

    trigger_human_name = trigger.to_s.tr('_', ' ').camelize

    link_to path, rel: 'nofollow', method: :post do
      content_tag(:span, trigger_human_name)
    end
  end

  def link_to_edit_hook(hook)
    case hook
    when GroupHook
      edit_group_hook_path(hook.group, hook)
    when ProjectHook
      edit_project_hook_path(hook.project, hook)
    when SystemHook
      edit_admin_hook_path(hook)
    end
  end

  def link_to_destroy_hook(hook)
    case hook
    when GroupHook
      group_hook_path(hook.group, hook)
    when ProjectHook
      project_hook_path(hook.project, hook)
    when SystemHook
      admin_hook_path(hook)
    end
  end
end
