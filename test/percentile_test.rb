require_relative "test_helper"

class PercentileTest < Minitest::Test
  def setup
    skip if mongoid?

    User.delete_all
  end

  def test_even
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    assert_equal 76, User.percentile(:visits_count, 0.95)
  end

  def test_odd
    [1, 1, 2, 4, 100].each { |n| User.create!(visits_count: n) }
    assert_in_delta 80.8, User.percentile(:visits_count, 0.95)
  end

  def test_bad
    [1, 1, 2, 3, 4, 100].each { |n| User.create!(visits_count: n) }
    # prevents injection, returns 0th percentile
    # TODO throw error?
    assert_equal 1, User.percentile(:visits_count, "bad")
  end
end
