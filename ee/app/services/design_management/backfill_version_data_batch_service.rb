# frozen_string_literal: true

module DesignManagement
  class BackfillVersionDataBatchService
    include BackfillVersionDataSharedScope

    def initialize(issue_id)
      @issue = Issue.find(issue_id)
    end

    def execute
      logger.info(message: 'Backfilling author_id and created_at for versions belonging to issue', issue_id: issue.id)

      ActiveRecord::Base.transaction do
        versions.each do |version|
          c = commits[version.sha]

          if c.nil?
            # This should never happen because without a corresponding `Commit`
            # we can never display a design image for the `Version`.
            # However, let's log.
            logger.error(message: 'No commit found for version', issue_id: issue.id, version_id: version.id)
          else
            version.update_columns(created_at: c.created_at, author_id: c.author.id)
          end
        end
      end
    end

    private

    attr_reader :issue

    # Log to `migrations.log`.
    def logger
      Gitlab::BackgroundMigration::Logger
    end

    def versions
      @versions ||= issue.design_versions.merge(self.class.versions_with_missing_author_or_created_at)
    end

    def commits
      @commits ||= begin
        repository = issue.project.design_repository

        commits = repository.commits_by(oids: versions.map(&:sha))
        # Batch load the commit authors so the `User` records are fetched
        # all at once the first time we call `commit.author.id`.
        commits.each(&:lazy_author)

        commits.each_with_object({}) do |commit, hash|
          hash[commit.id] = commit
        end
      end
    end
  end
end
