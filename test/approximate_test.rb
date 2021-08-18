require_relative "test_helper"

class ApproximateTest < Minitest::Test
  def setup
    skip unless approximate?
    User.delete_all
  end

  def test_even
    [1, 2, 3, 4].each { |n| User.create!(visits_count: n) }
    assert_in_delta 3.5, User.percentile(:visits_count, 0.75, approximate: true)
  end

  def test_odd
    [15, 20, 35, 40, 50].each { |n| User.create!(visits_count: n) }
    assert_equal 27.5, User.percentile(:visits_count, 0.4, approximate: true)
  end

  def test_empty
    assert_nil User.percentile(:visits_count, 0.75, approximate: true)
  end

  def test_null
    [1, 2, 3, 4, nil].each { |n| User.create!(visits_count: n) }
    assert_in_delta 3.5, User.percentile(:visits_count, 0.75, approximate: true)
  end

  def test_all_null
    [nil, nil, nil].each { |n| User.create!(visits_count: n) }
    assert_nil User.percentile(:visits_count, 0.75, approximate: true)
  end

  def test_group
    [1, 2, 3, 4, 15, 20, 35, 40, 50].each { |n| User.create!(visits_count: n, name: n <= 4 ? "A" : "B") }
    expected = {"A" => 3.5, "B" => 42.5}
    assert_equal expected, User.group(:name).percentile(:visits_count, 0.75, approximate: true)
  end
end
