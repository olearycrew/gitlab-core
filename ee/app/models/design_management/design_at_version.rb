# frozen_string_literal: true

# Tuple of design and version
# * has a composite ID, with lazy_find
class DesignManagement::DesignAtVersion
  include ActiveModel::Validations

  attr_accessor :version
  attr_accessor :design

  validates_presence_of :version
  validates_presence_of :design

  def initialize(design: nil, version: nil)
    @design, @version = design, version
  end

  def self.lazy_find(id)
    BatchLoader.for(id).batch do |ids, found|
      find_all.for_ids(ids).each do |record|
        found[record.id, record]
      end
    end
  end

  def id
    "#{design.id}.#{version.id}"
  end

  def global_id
    Gitlab::GlobalId.build(model_name: 'DesignManagement::DesignAtVersion', id: id)
  end

  def save!
    validate!
  end

  def persisted?
    design.persisted? && version.persisted?
  end

  def self.find_all
    Query.new
  end

  # We can't fall back to ActiveRecord here and remain as efficient as we might like,
  # since we want to avoid N+1 queries. By using Arel, we can always query for any number
  # of designs-at-versions in 1 query, and load designs and versions from the same row.
  #
  # This guarantees:
  #  * we only load valid designs-at-versions (i.e. those where the design and version
  #    are on the same issue)
  #  * we only load combinations that exist
  #  * we don't load combinations that are not requested when ids are provided.
  class Query
    include Enumerable

    attr_reader :query

    def initialize
      @query = Arel::SelectManager.new(designs_table)
                  .join(versions_table)
                  .on(share_issue)
    end

    def each(&block)
      to_records.each(&block)
    end

    def for_ids(ids)
      pairs = ids.map { |id| id.split('.').map(&:to_i) }

      design_mentioned  = pairs_table[:design_id].eq(designs_table[:id])
      version_mentioned = pairs_table[:version_id].eq(versions_table[:id])

      cte = Arel::Nodes::As.new(pairs_table, select_pairs(pairs))

      query.with(cte).join(pairs_table).on(design_mentioned.and(version_mentioned))

      self
    end

    def count
      query.project(designs_table[:id].count)
      res = ActiveRecord::Base.connection.exec_query(query.to_sql)
      res.first['count']
    end

    def empty?
      count.zero?
    end

    def to_records
      query.project(designs_table[Arel.star], versions_table[Arel.star])
      res = ActiveRecord::Base.connection.exec_query(query.to_sql)

      _, n = res.columns.each.with_index.find { |c, i| c == 'id' && i > 0 }
      d_cols = res.columns.take(n)
      v_cols = res.columns.drop(n)

      res.rows.map do |row|
        d = ::DesignManagement::Design.instantiate(d_cols.zip(row.take(n)).to_h)
        v = ::DesignManagement::Version.instantiate(v_cols.zip(row.drop(n)).to_h)
        ::DesignManagement::DesignAtVersion.new(design: d, version: v)
      end
    end
    alias_method :to_a, :to_records

    private :to_records

    private

    def share_issue
      designs_table[:issue_id].eq(versions_table[:issue_id])
    end

    def designs_table
      ::DesignManagement::Design.arel_table
    end

    def versions_table
      ::DesignManagement::Version.arel_table
    end

    def pairs_table
      Arel::Table.new('pairs')
    end

    def select_pairs(pairs)
      pairs_table_def = Arel::Nodes::SqlLiteral.new('t (design_id, version_id)')
      pairs_values = Arel::Nodes::Grouping.new(Arel::Nodes::ValuesList.new(pairs))
      pairs_alias = Arel::Nodes::TableAlias.new(pairs_values, pairs_table_def)

      Arel::SelectManager.new(pairs_alias).project(Arel.star)
    end
  end
end
