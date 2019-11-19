# frozen_string_literal: true

module Banzai
  module Filter
    class DesignReferenceFilter < AbstractReferenceFilter
      def find_object(project, ids)
        issue = indexed_issues.dig(project.id, ids[:issue_iid])

        designs_per_project.dig(project.id, issue.id, ids[:filename]) if issue.present?
      end

      def designs_per_project
        @designs_per_project ||= begin
          issues = indexed_issues

          coords = parent_per_reference.to_a.flat_map do |(path, project)|
            references_per_parent[path].map do |ids|
              issue = issues.dig(project.id, ids[:issue_iid])
              { issue_id: issue.id, **ids } if issue.present?
            end.compact
          end

          designs = DesignManagement::Design.for_reference.by_composite_id(coords)

          Gitlab::Utils.index_by_multikey(designs, :project_id, :issue_id, :filename)
        end
      end

      # We are not using this mechanism. This method is disabled to avoid
      # upstream changes in parent classes that might call it.
      def records_per_parent
        raise NotImplementedError
      end

      # Preload all issues so that we can translate efficiently between iid and id.
      def indexed_issues
        @issue_ids_by_iid_and_project_id ||=
          begin
            coords = references_per_parent.each_with_object([]) do |(project_path, ids), arr|
              project = parent_per_reference[project_path]
              next unless project.present?

              ids.each { |id| arr << { project_id: project.id, iid: id[:issue_iid] } }
            end

            issues = Issue.by_project_id_and_iid(coords).select(:project_id, :iid, :id)

            Gitlab::Utils.index_by_multikey(issues, :project_id, :iid)
          end
      end

      def issue_iids_by_id
        @issue_iids_by_id ||= indexed_issues.each_with_object({}) do |(_, by_project), iids_by_id|
          by_project.each {|iid, issue| iids_by_id[issue.id] = iid }
        end
      end

      def parent_type
        :project
      end

      def url_for_object(design, project)
        path_options = { vueroute: design.filename }
        Gitlab::Routing.url_helpers.designs_project_issue_path(project, design.issue, path_options)
      end

      def data_attributes_for(text, project, design, link_content: false, link_reference: false)
        super.merge(issue: design.issue_id)
      end

      def self.object_class
        ::DesignManagement::Design
      end

      def self.object_sym
        :design
      end

      def self.parse_symbol(raw, match_data)
        filename = if efn = match_data[:escaped_filename]
                     efn.gsub(/(\\ \\ | \\ ")/x) { |x| x[1] }
                   elsif b64_name = match_data[:base_64_encoded_name]
                     Base64.decode64(b64_name)
                   elsif name = match_data[:simple_file_name]
                     name
                   else
                     raise "Unexpected name format: #{raw}"
                   end

        { filename: filename, issue_iid: match_data[:issue].to_i }
      end
    end
  end
end
