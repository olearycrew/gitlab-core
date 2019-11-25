# frozen_string_literal: true
class Packages::PackageDependency < ApplicationRecord
  belongs_to :package
  has_many :package_dependency_links

  validates :package, :name, :version_pattern, presence: true

  validates :name,
    uniqueness: { scope: %i[package_id version_pattern] }

  def self.for_names_and_version_patterns(names = [], version_patterns = [], chunk_size = 50)
    raise ArgumentError, "Parameters sizes don't match" unless names.size == version_patterns.size

    sanitized_names = names.map { |n| connection.quote(n) }
    sanitized_version_patterns = version_patterns.map { |n| connection.quote(n) }
    columns = "(#{connection.quote_column_name(:name)}, #{connection.quote_column_name(:version_pattern)})"
    matched_ids = []
    sanitized_names.zip(sanitized_version_patterns).each_slice(chunk_size) do |tuples|
      where_statement = <<-EOF
        #{columns} IN
        (#{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')})
      EOF
      matched_ids << where(where_statement).pluck(:id)
    end

    matched_ids.flatten!
    return none if matched_ids.empty?

    where(id: matched_ids)
  end

  def self.pluck_ids_and_names
    pluck(:id, :name)
  end
end
