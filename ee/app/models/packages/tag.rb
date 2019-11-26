# frozen_string_literal: true
class Packages::Tag < ApplicationRecord
  belongs_to :package

  validates :package, :name, presence: true

  validates :name, uniqueness: { scope: :package_id }

  scope :for_packages, -> (packages) { where(package_id: packages.select(:id)) }
end
