# frozen_string_literal: true

class AddPackageIdNameIndexToPackagesPackageTags < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_package_tags, [:package_id, :name], unique: true
  end

  def down
    remove_concurrent_index :packages_package_tags, [:package_id, :name], unique: true
  end
end
