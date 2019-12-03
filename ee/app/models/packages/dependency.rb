# frozen_string_literal: true
class Packages::Dependency < ApplicationRecord
  belongs_to :package
  has_many :dependency_links, class_name: 'Packages::DependencyLink'

  validates :package, :name, :version_pattern, presence: true

  validates :name,
    uniqueness: { scope: %i[package_id version_pattern] }

  NAME_VERSION_PATTERN_TUPLE_MATCHING = '(name, version_pattern) = (?, ?)'.freeze
  MAX_STRING_LENGTH = 255.freeze

  def self.for_names_and_version_patterns(names_and_version_patterns = {}, chunk_size = 50, max_rows_limit = 200)
    names_and_version_patterns.reject! { |key, value| key.size > MAX_STRING_LENGTH || value.size > MAX_STRING_LENGTH }
    matched_ids = []
    names_and_version_patterns.each_slice(chunk_size) do |tuples|
      where_statement = Array.new(tuples.size, NAME_VERSION_PATTERN_TUPLE_MATCHING)
                             .join(' OR ')
      ids = where(where_statement, *tuples.flatten)
              .limit(max_rows_limit + 1)
              .pluck(:id)
      matched_ids.concat(ids)

      raise ArgumentError, "Parameters select too many Dependencies" if matched_ids.size > max_rows_limit
    end

    return none if matched_ids.empty?

    where(id: matched_ids)
  end

  def self.pluck_ids_and_names
    pluck(:id, :name)
  end
end
