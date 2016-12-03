require_relative "test_helper"

class TestActiveMedian < Minitest::Test
  def setup
    ActiveMedian.create_function
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

  def test_decimal
    6.times { |n| User.create!(latitude: n * 0.1) }
    assert_equal 0.25, User.median(:latitude)
  end

  def test_float
    6.times { |n| User.create!(rating: n * 0.1) }
    assert_equal 0.25, User.median(:rating)
  end

  def test_drop
    ActiveMedian.drop_function
    error = assert_raises(ActiveRecord::StatementInvalid) { User.median(:visits_count) }
    assert_includes error.message, "PG::UndefinedFunction"
  end
end
