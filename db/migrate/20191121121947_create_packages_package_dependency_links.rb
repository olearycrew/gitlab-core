# frozen_string_literal: true

class CreatePackagesPackageDependencyLinks < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_package_dependency_links do |t|
      t.references :package, index: false, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.references :package_dependency, index: { name: 'idx_pkgs_package_dependency_links_on_package_dependency_id' }, null: false, foreign_key: { to_table: :packages_package_dependencies, on_delete: :cascade }, type: :bigint
      t.integer :dependency_type, limit: 2, null: false
    end

    add_index :packages_package_dependency_links, [:package_id, :package_dependency_id, :dependency_type], unique: true, name: 'idx_pkgs_package_dep_links_on_pkg_id_pkg_dependency_id_dep_type'
  end
end
