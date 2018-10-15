require_relative "test_helper"

class TestActiveMedian < Minitest::Test
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
    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    expected = {"A" => 2, "B" => 5}
    assert_equal expected, User.group(:name).median(:visits_count)
  end

  def test_complex_group
    [1, 2, 3, 4, 5, 6].each { |n| User.create!(visits_count: n, name: n < 4 ? "A" : "B") }
    expected = {"AC" => 2, "BC" => 5}
    group = sqlite? ? "name || 'C'" : "CONCAT(name, 'C')"
    assert_equal expected, User.group(group).median(:visits_count)
  end

  def test_double_group
    [1, 2, 3, 4, 5, 6].each { |n| User.create!(rating: n, name: n < 4 ? "A" : "B", visits_count: n < 4 ? 1 : 2) }
    expected = {["A", 1] => 2, ["B", 2] => 5}
    assert_equal expected, User.group(:name).group(:visits_count).median(:rating)
  end

  def test_association
    user = User.create!
    user.posts.create!(comments_count: 1)
    assert_equal 1, user.posts.median(:comments_count)
  end
end
