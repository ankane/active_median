require_relative "test_helper"

class PercentileTest < Minitest::Test
  def setup
    User.delete_all
  end

  def test_even
    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_in_delta 3.25, User.percentile(:visits_count, 0.75)
  end

  def test_odd
    [15, 20, 35, 40, 50].each { |n| User.create!(visits_count: n) }
    assert_equal 29, User.percentile(:visits_count, 0.4)
  end

  def test_empty
    assert_nil User.percentile(:visits_count, 0.75)
  end

  def test_null
    [1, 2, 3, 4, nil].each { |n| User.create!(visits_count: n) }
    assert_in_delta 3.25, User.percentile(:visits_count, 0.75)
  end

  def test_all_null
    [nil, nil, nil].each { |n| User.create!(visits_count: n) }
    assert_nil User.percentile(:visits_count, 0.75)
  end

  def test_zero
    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_equal 1, User.percentile(:visits_count, 0)
  end

  def test_one
    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_equal 4, User.percentile(:visits_count, 1)
  end

  def test_high
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    assert_in_delta 95.2, User.percentile(:visits_count, 0.99)
  end

  def test_group
    skip if mongoid?

    [1, 2, 3, 4, 15, 20, 35, 40, 50].each { |n| User.create!(visits_count: n, name: n <= 4 ? "A" : "B") }
    expected = {"A" => 3.25, "B" => 40}
    assert_equal expected, User.group(:name).percentile(:visits_count, 0.75)
  end

  def test_order
    skip if mongoid?

    User.create!(visits_count: 2)
    assert 2, User.order(:created_at).average(:visits_count)
    assert 2, User.order(:created_at).percentile(:visits_count, 0.5)
  end

  def test_group_order
    skip if mongoid?

    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    assert_equal "A", User.group(:name).order(:name).average(:visits_count).keys.first
    assert_equal "B", User.group(:name).order("average_visits_count desc").average(:visits_count).keys.first
    assert_equal "A", User.group(:name).order(:name).percentile(:visits_count, 0.5).keys.first
    assert_equal "B", User.group(:name).order("percentile_visits_count desc").percentile(:visits_count, 0.5).keys.first
  end

  def test_expression
    skip if mongoid?

    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_in_delta 4.25, User.percentile(Arel.sql("visits_count + 1"), 0.75)
  end

  def test_expression_no_arel
    skip if mongoid?

    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      User.percentile("visits_count + 1", 0.75)
    end
    assert_equal "Query method called with non-attribute argument(s): \"visits_count + 1\". Use Arel.sql() for known-safe values.", error.message
  end

  def test_bad_percentile_string
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    error = assert_raises(ArgumentError) do
      User.percentile(:visits_count, "bad")
    end
    assert_equal "invalid percentile", error.message
  end

  def test_bad_percentile_nil
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    error = assert_raises(ArgumentError) do
      User.percentile(:visits_count, nil)
    end
    assert_equal "invalid percentile", error.message
  end

  def test_bad_percentile
    error = assert_raises(ArgumentError) do
      User.percentile(:visits_count, 1.1)
    end
    assert_equal "percentile is not between 0 and 1", error.message
  end

  def test_array_even
    assert_in_delta 3.25, [1, 2, 3, 4].percentile(0.75)
  end

  def test_array_odd
    assert_equal 29, [15, 20, 35, 40, 50].percentile(0.4)
  end

  def test_array_zero
    assert_equal 1, [1, 2, 3, 4].percentile(0)
  end

  def test_array_one
    assert_equal 4, [1, 2, 3, 4].percentile(1)
  end

  def test_array_high
    assert_in_delta 95.2, [1, 1, 2, 3, 4, 100].percentile(0.99)
  end

  def test_array_bad_percentile
    error = assert_raises(ArgumentError) do
      [1, 2, 3].percentile(1.1)
    end
    assert_equal "percentile is not between 0 and 1", error.message
  end
end
