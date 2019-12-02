# frozen_string_literal: true
class Packages::Dependency < ApplicationRecord
  belongs_to :package
  has_many :dependency_links, class_name: 'Packages::DependencyLink'

  validates :package, :name, :version_pattern, presence: true

  validates :name,
    uniqueness: { scope: %i[package_id version_pattern] }

  NAME_VERSION_PATTERN_TUPLE_MATCHING = '(name, version_pattern) = (?, ?)'.freeze

  def self.for_names_and_version_patterns(names = [], version_patterns = [], chunk_size = 50, max_rows_limit = 200)
    raise ArgumentError, "Parameters sizes don't match" unless names.size == version_patterns.size

    matched_ids = []
    names.zip(version_patterns).each_slice(chunk_size) do |tuples|
      where_statement = Array.new(tuples.size, NAME_VERSION_PATTERN_TUPLE_MATCHING)
                             .join(' OR ')
      matched_ids.concat(where(where_statement, *tuples.flatten).pluck(:id))

      raise ArgumentError, "Parameters select too many Dependencies" if matched_ids.size > max_rows_limit
    end

    return none if matched_ids.empty?

    where(id: matched_ids)
  end

  def self.pluck_ids_and_names
    pluck(:id, :name)
  end
end
