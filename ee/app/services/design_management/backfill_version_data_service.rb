# frozen_string_literal: true

module DesignManagement
  class BackfillVersionDataService
    include BackfillVersionDataSharedScope

    # rubocop: disable CodeReuse/ActiveRecord
    def self.execute
      # For every issue with version records that need updating,
      # update the `Version` records for that issue.
      versions_with_missing_author_or_created_at.select(:issue_id).distinct.each do |version|
        BackfillVersionDataBatchService.new(version.issue_id).execute
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
