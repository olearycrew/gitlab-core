# frozen_string_literal: true

FactoryBot.modify do
  factory :note do
    trait :on_epic do
      noteable { create(:epic) }
      project { nil }
    end

    trait :on_design do
      noteable { create(:design, :with_file, project: project) }
    end

    trait :with_review do
      review
    end
  end
end

FactoryBot.define do
  factory :note_on_epic, parent: :note, traits: [:on_epic]

  factory :diff_note_on_design, parent: :note, traits: [:on_design], class: DiffNote do
    note { generate(:title) }
    author { project&.creator || create(:user) }

    position { build(:image_diff_position, file: noteable.full_path) }
  end
end
