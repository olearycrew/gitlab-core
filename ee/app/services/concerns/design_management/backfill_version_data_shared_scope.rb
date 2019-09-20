# frozen_string_literal: true

# Concern provides a scope that is used only for the backfilling
# of version data migrations.
module DesignManagement
  module BackfillVersionDataSharedScope
    extend ActiveSupport::Concern

    class_methods do
      # rubocop: disable CodeReuse/ActiveRecord
      def versions_with_missing_author_or_created_at
        Version.where(author_id: nil).or(Version.where(created_at: nil))
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
