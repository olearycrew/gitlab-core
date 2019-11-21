# frozen_string_literal: true
FactoryBot.define do
  factory :package_dependency, class: Packages::PackageDependency do
    package
    sequence(:name) { |n| "@test/package-#{n}"}
    sequence(:version_pattern) { |n| "~6.2.#{n}" }
  end
end
