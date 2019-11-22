# frozen_string_literal: true

module CompositeId
  extend ActiveSupport::Concern

  class_methods do
    # Apply a set of constraints that function as composite IDs.
    #
    # This is the plural form of the standard ActiveRecord idiom:
    # `where(foo: x, bar: y)`, except it allows multiple pairs of `x` and
    # `y` to be specified, with the semantics that translate to:
    #
    # ```sql
    # WHERE
    #     (foo = x_0 AND bar = y_0)
    #  OR (foo = x_1 AND bar = y_1)
    #  OR ...
    # ```
    #
    # or the equivalent:
    #
    # ```sql
    # WHERE
    #   (foo, bar) IN ((x_0, y_0), (x_1, y_1), ...)
    # ```
    #
    # @param permitted_keys [Array<Symbol>] The keys each hash must have
    # @param hashes [Array<Hash>|Hash] The constraints
    #
    # e.g.:
    # ```
    #   where_composite(%i[foo bar], [{foo: 1, bar: 2}, {foo: 1, bar: 3}])
    # ```
    #
    def where_composite(permitted_keys, hashes)
      raise ArgumentError, 'no permitted_keys' unless permitted_keys.present?

      hashes = Array.wrap(hashes)

      return none if hashes.empty?

      clauses = hashes.map do |hash|
        permitted_keys.map do |key|
          # We enforce that the arguments have the expected keys:
          raise ArgumentError, "all arguments must contain #{permitted_keys}" unless hash.has_key?(key)

          arel_table[key].eq(hash[key])
        end.reduce(:and)
      end

      where(clauses.reduce(:or))
    end
  end
end
