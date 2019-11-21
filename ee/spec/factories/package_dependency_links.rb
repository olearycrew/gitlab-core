# frozen_string_literal: true
FactoryBot.define do
  factory :package_dependency_link, class: Packages::PackageDependencyLink do
    package
    package_dependency { create(:package_dependency, package: package) }
    dependency_type { :dependencies }
  end
end
