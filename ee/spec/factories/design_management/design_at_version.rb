# frozen_string_literal: true

FactoryBot.define do
  factory :design_at_version, class: DesignManagement::DesignAtVersion do
    transient do
      issue { design&.issue || version&.issue || create(:issue) }
    end

    after(:build) do |dav, evaluator|
      dav.design ||= create(:design, issue: evaluator.issue)
      dav.version ||= create(:design_version, issue: evaluator.issue, designs: [dav.design])
    end
  end
end
