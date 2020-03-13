require_relative "test_helper"

class PercentileTest < Minitest::Test
  def setup
    skip if mongoid? || sqlite?

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

  def test_zero
    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_equal 1, User.percentile(:visits_count, 0)
  end

  def test_one
    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_equal 4, User.percentile(:visits_count, 1)
  end

  def test_bad_column
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    # prevents injection, returns 0th percentile
    # TODO throw error?
    assert_equal 1, User.percentile(:visits_count, "bad")
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

  def test_array_bad_percentile
    error = assert_raises(ArgumentError) do
      [1, 2, 3].percentile(1.1)
    end
    assert_equal "percentile is not between 0 and 1", error.message
  end
end
