# frozen_string_literal: true

class CreatePackagesDependencies < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :packages_dependencies do |t|
      t.references :package, index: false, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.string :name, null: false, limit: 255
      t.string :version_pattern, null: false, limit: 255
    end

    add_index :packages_dependencies, [:package_id, :name, :version_pattern], unique: true, name: 'idx_pkgs_dependencies_package_id_name_version_pattern'
  end
end
