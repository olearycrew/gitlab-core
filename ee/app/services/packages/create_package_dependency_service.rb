# frozen_string_literal: true
module Packages
  class CreatePackageDependencyService < BaseService
    attr_reader :package, :dependencies

    def initialize(package, dependencies)
      @package = package
      @dependencies = dependencies
    end

    def execute
      Packages::PackageDependencyLink.dependency_types.keys.each do |type|
        create_dependency(type)
      end
    end

    private

    def create_dependency(type)
      return unless dependencies.key?(type)

      names_and_version_patterns = dependencies[type].to_a
      existing_ids, existing_names = find_existing_ids_and_names(names_and_version_patterns)
      package_dependencies_to_insert = names_and_version_patterns

      if existing_names.any?
        package_dependencies_to_insert = names_and_version_patterns.reject { |e| e.first.in?(existing_names) }
      end

      inserted_ids = bulk_insert_package_dependencies(package_dependencies_to_insert)
      bulk_insert_package_dependency_links(type, (existing_ids + inserted_ids))
    end

    def find_existing_ids_and_names(names_and_version_patterns)
      names = names_and_version_patterns.map(&:first)
      version_patterns = names_and_version_patterns.map(&:second)

      existing_rows = package.package_dependencies.for_names_and_version_patterns(names, version_patterns)
                                                  .pluck_ids_and_names
      [existing_rows.map(&:first) || [], existing_rows.map(&:second) || []]
    end

    def bulk_insert_package_dependencies(names_and_version_patterns)
      return [] if names_and_version_patterns.empty?

      rows = names_and_version_patterns.map do |name_and_version_pattern|
        {
          name: name_and_version_pattern[0],
          version_pattern: name_and_version_pattern[1],
          package_id: package.id
        }
      end

      database.bulk_insert(Packages::PackageDependency.table_name, rows, return_ids: true)
    end

    def bulk_insert_package_dependency_links(type, package_dependency_ids)
      rows = package_dependency_ids.map do |package_dependency_id|
        {
          package_id: package.id,
          package_dependency_id: package_dependency_id,
          dependency_type: Packages::PackageDependencyLink.dependency_types[type.to_s]
        }
      end

      database.bulk_insert(Packages::PackageDependencyLink.table_name, rows)
    end

    def database
      ::Gitlab::Database
    end
  end
end
