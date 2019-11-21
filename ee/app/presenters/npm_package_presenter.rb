# frozen_string_literal: true

class NpmPackagePresenter
  include API::Helpers::RelatedResourcesHelpers

  attr_reader :name, :packages

  NPM_VALID_DEPENDENCY_TYPES = %i[dependencies devDependencies bundleDependencies peerDependencies deprecated].freeze

  def initialize(name, packages)
    @name = name
    @packages = packages
  end

  def versions
    package_versions = {}

    packages.each do |package|
      package_file = package.package_files.last

      next unless package_file

      package_versions[package.version] = build_package_version(package, package_file)
    end

    package_versions
  end

  def dist_tags
    {
      latest: sorted_versions.last
    }
  end

  private

  def build_package_version(package, package_file)
    {
      name: package.name,
      version: package.version,
      dist: {
        shasum: package_file.file_sha1,
        tarball: tarball_url(package, package_file)
      }
    }.tap do |package_version|
      package_version.merge!(build_package_dependencies(package))
    end
  end

  def tarball_url(package, package_file)
    expose_url "#{api_v4_projects_path(id: package.project_id)}" \
      "/packages/npm/#{package.name}" \
      "/-/#{package_file.file_name}"
  end

  def build_package_dependencies(package)
    return {} unless package.package_dependency_links.exists?

    package_dependencies = Hash.new { |h, key| h[key] = {} }
    NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
      dependency_links = package.package_dependency_links
                                .with_dependency_type(dependency_type)

      dependency_links.find_each do |dependency_link|
        package_dependency = dependency_link.package_dependency
        package_dependencies[dependency_type][package_dependency.name] = package_dependency.version_pattern
      end
    end
    package_dependencies
  end

  def sorted_versions
    versions = packages.map(&:version).compact
    VersionSorter.sort(versions)
  end
end
