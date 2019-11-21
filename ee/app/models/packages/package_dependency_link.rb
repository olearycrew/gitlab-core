# frozen_string_literal: true
class Packages::PackageDependencyLink < ApplicationRecord
  belongs_to :package
  belongs_to :package_dependency

  validates :package, :package_dependency, presence: true

  validates :dependency_type,
    uniqueness: { scope: %i[package_id package_dependency_id] },
    if: -> { package_id? && package_dependency_id? }

  enum dependency_type: { dependencies: 1, devDependencies: 2, bundleDependencies: 3, peerDependencies: 4, deprecated: 5 }

  scope :with_dependency_type, ->(dependency_type) { where(dependency_type: dependency_type) }
end
