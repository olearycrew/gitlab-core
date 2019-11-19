# frozen_string_literal: true

require 'spec_helper'

describe CompositeId do
  describe '.where_composite' do
    let_it_be(:test_table_name) { "test_table_#{SecureRandom.hex(10)}" }

    let(:model) do
      tbl_name = test_table_name
      Class.new(ActiveRecord::Base) do
        self.table_name = tbl_name

        include CompositeId
      end
    end

    def connection
      ActiveRecord::Base.connection
    end

    before :all do
      c = connection

      c.drop_table(test_table_name) if c.data_source_exists?(test_table_name)
      c.create_table(test_table_name) do |t|
        t.integer :foo
        t.integer :bar
        t.string  :wibble
      end
    end

    after :all do
      connection.drop_table(test_table_name)
    end

    it 'requires at least one permitted key' do
      expect { model.where_composite([], nil) }
        .to raise_error(ArgumentError)
    end

    it 'requires all arguments to match the permitted_keys' do
      expect { model.where_composite([:foo], [{ foo: 1 }, { bar: 2 }]) }
        .to raise_error(ArgumentError)
    end

    it 'returns an empty relation if there are no arguments' do
      expect(model.where_composite([:foo, :bar], nil))
        .to be_empty

      expect(model.where_composite([:foo, :bar], []))
        .to be_empty
    end

    it 'permits extra arguments' do
      a = model.where_composite([:foo, :bar], { foo: 1, bar: 2 })
      b = model.where_composite([:foo, :bar], { foo: 1, bar: 2, baz: 3 })

      expect(a.to_sql).to eq(b.to_sql)
    end

    it 'can handle multiple fields' do
      fields = [:foo, :bar, :wibble]
      args = { foo: 1, bar: 2, wibble: 'wobble' }
      pattern = %r{
        WHERE \s+
          \(?
             \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s+ AND
             \s+ "#{test_table_name}"\."wibble" \s* = \s* 'wobble'
             \s*
          \)?
      }x

      expect(model.where_composite(fields, args).to_sql).to match(pattern)
    end

    it 'constructs (A&B) for one argument' do
      fields = [:foo, :bar]
      args = [
        { foo: 1, bar: 2 }
      ]
      pattern = %r{
        WHERE \s+
          \(?
             \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s*
          \)?
      }x

      expect(model.where_composite(fields, args).to_sql).to match(pattern)
      expect(model.where_composite(fields, args[0]).to_sql).to match(pattern)
    end

    it 'constructs (A&B) OR (C&D) for two arguments' do
      args = [
        { foo: 1, bar: 2 },
        { foo: 3, bar: 4 }
      ]
      pattern = %r{
        WHERE \s+
          \( \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s* \)?
          \s* OR \s*
          \(? \s* "#{test_table_name}"\."foo" \s* = \s* 3
              \s+ AND
              \s+ "#{test_table_name}"\."bar" \s* = \s* 4
              \s* \)
      }x

      q = model.where_composite([:foo, :bar], args)

      expect(q.to_sql).to match(pattern)
    end

    it 'constructs (A&B) OR (C&D) OR (E&F) for three arguments' do
      args = [
        { foo: 1, bar: 2 },
        { foo: 3, bar: 4 },
        { foo: 5, bar: 6 }
      ]
      pattern = %r{
        WHERE \s+
          \({2}
             \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s* \)?
          \s* OR \s*
          \(? \s* "#{test_table_name}"\."foo" \s* = \s* 3
              \s+ AND
              \s+ "#{test_table_name}"\."bar" \s* = \s* 4
              \s* \)?
          \s* OR \s*
          \(? \s* "#{test_table_name}"\."foo" \s* = \s* 5
              \s+ AND
              \s+ "#{test_table_name}"\."bar" \s* = \s* 6
              \s* \)
      }x

      q = model.where_composite([:foo, :bar], args)

      expect(q.to_sql).to match(pattern)
    end

    it 'constructs correct trees of constraints for large sets' do
      args = (0..100).map { |n| { foo: n, bar: n * n, wibble: 'x' * n } }

      q = model.where_composite([:foo, :bar, :wibble], args)
      sql = q.to_sql

      expect(sql.scan(/OR/).count).to eq(args.size - 1)
      expect(sql.scan(/AND/).count).to eq(2 * args.size)
    end
  end
end
