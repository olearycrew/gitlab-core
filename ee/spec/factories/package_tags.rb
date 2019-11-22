# frozen_string_literal: true
FactoryBot.define do
  factory :package_tag, class: Packages::PackageTag do
    package
    sequence(:name) { |n| "tag-#{n}"}
  end
end
