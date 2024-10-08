require_relative "test_helper"

class MedianTest < Minitest::Test
  def setup
    User.delete_all
  end

  def test_even
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    assert_equal 2.5, User.median(:visits_count)
  end

  def test_odd
    [1, 1, 2, 4, 100].each { |n| User.create!(visits_count: n) }
    assert_equal 2, User.median(:visits_count)
  end

  def test_empty
    assert_nil User.median(:visits_count)
  end

  def test_null
    [1, 1, 2, 3, 4, 100, nil].each { |n| User.create!(visits_count: n) }
    assert_equal 2.5, User.median(:visits_count)
  end

  def test_all_null
    [nil, nil, nil].each { |n| User.create!(visits_count: n) }
    assert_nil User.median(:visits_count)
  end

  def test_decimal
    skip if sqlite? # unsure why
    6.times { |n| User.create!(latitude: n * 0.1) }
    assert_equal 0.25, User.median(:latitude)
  end

  def test_float
    6.times { |n| User.create!(rating: n * 0.1) }
    assert_in_delta 0.25, User.median(:rating)
  end

  def test_group
    skip if mongoid?

    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    expected = {"A" => 2, "B" => 5}
    assert_equal expected, User.group(:name).median(:visits_count)
  end

  def test_complex_group
    skip if mongoid?

    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    expected = {"AC" => 2, "BC" => 5}
    group = sqlite? ? "name || 'C'" : "CONCAT(name, 'C')"
    assert_equal expected, User.group(group).median(:visits_count)
  end

  def test_double_group
    skip if mongoid?

    [1, 2, 3, 4, 5, 6].each { |n| User.create!(rating: n, name: n < 4 ? "A" : "B", visits_count: n < 4 ? 1 : 2) }
    expected = {["A", 1] => 2, ["B", 2] => 5}
    assert_equal expected, User.group(:name).group(:visits_count).median(:rating)
  end

  def test_select
    skip if mongoid?

    [1, 1, 2, 3, 4, 13].each { |n| User.create!(visits_count: n) }
    assert_equal 4, User.select(:id).average(:visits_count)
    assert_equal 2.5, User.select(:id).median(:visits_count)
  end

  def test_select_group
    skip if mongoid?

    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    expected = {"A" => 2, "B" => 5}
    assert_equal expected, User.select(:id).group(:name).average(:visits_count)
    assert_equal expected, User.select(:id).group(:name).median(:visits_count)
  end

  def test_order
    skip if mongoid?

    User.create!(visits_count: 2)
    assert 2, User.order(:created_at).average(:visits_count)
    assert 2, User.order(:created_at).median(:visits_count)
  end

  def test_group_order
    skip if mongoid?

    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    assert_equal "A", User.group(:name).order(:name).average(:visits_count).keys.first
    assert_equal "B", User.group(:name).order("average_visits_count desc").average(:visits_count).keys.first
    assert_equal "A", User.group(:name).order(:name).median(:visits_count).keys.first
    assert_equal "B", User.group(:name).order("median_visits_count desc").median(:visits_count).keys.first
  end

  def test_expression
    skip if mongoid?

    [1, 1, 2, 4, 100].each { |n| User.create!(visits_count: n) }
    assert_equal 3, User.median(Arel.sql("visits_count + 1"))
  end

  def test_expression_no_arel
    skip if mongoid?

    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      User.median("visits_count + 1")
    end
    assert_equal "Query method called with non-attribute argument(s): \"visits_count + 1\". Use Arel.sql() for known-safe values.", error.message
  end

  def test_column_resolution
    skip if mongoid?

    assert_nil User.joins(:posts).average(:id)
    assert_nil User.joins(:posts).median(:id)
  end

  def test_association
    user = User.create!
    user.posts.create!(comments_count: 1)
    assert_equal 1, user.posts.median(:comments_count)
  end

  def test_references
    skip if mongoid?

    user = User.create!
    user.posts.create!(comments_count: 1)
    # see https://github.com/ankane/active_median/issues/9
    # use left_outer_joins(:posts) instead
    assert_equal 1, User.includes(:posts).references(:posts).average(:comments_count)
    # assert_equal 1, User.includes(:posts).references(:posts).median(:comments_count)
  end

  def test_groupdate
    skip if adapter == "mysql2" || adapter == "trilogy" || adapter == "sqlserver" || mongoid?
    User.create!(visits_count: 5)
    result = User.group_by_day(:created_at, last: 2).median(:visits_count)
    assert_equal [nil, 5], result.values
    assert_kind_of Date, result.keys.first
  end

  def test_non_numeric
    # TODO debug mysql
    skip if adapter == "mysql2" || adapter == "trilogy" || mongoid?

    User.create!(name: 'A')
    assert_raises(ActiveRecord::StatementInvalid) do
      User.median(:name)
    end
  end

  def test_array_even
    assert_equal 2.5, [1, 1, 2, 3, 4, 100].median
  end

  def test_array_odd
    assert_equal 2, [1, 1, 2, 4, 100].median
  end

  def test_array_block
    assert_equal 5, [1, 1, 2, 3, 4, 100].median { |v| v * 2 }
  end

  def test_hash
    assert_raises do
      {a: 1, b: 1, c: 2}.median
    end
  end

  def test_hash_block
    assert_equal 2.5, {a: 1, b: 1, c: 2, d: 3, e: 4, f: 100}.median { |k, v| v }
  end

  def test_connection_leasing
    skip if mongoid?

    ActiveRecord::Base.connection_handler.clear_active_connections!
    assert_nil ActiveRecord::Base.connection_pool.active_connection?
    ActiveRecord::Base.connection_pool.with_connection do
      User.median(:visits_count)
    end
    assert_nil ActiveRecord::Base.connection_pool.active_connection?
  end
end
