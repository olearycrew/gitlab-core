class RenamePackagesPackageTags < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    rename_table(:packages_package_tags, :packages_tags)
  end
end
