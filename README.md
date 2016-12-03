# ActiveMedian

Median for ActiveRecord - PostgreSQL only at the moment

[![Build Status](https://travis-ci.org/ankane/active_median.svg)](https://travis-ci.org/ankane/active_median)

```ruby
Item.median(:price)
```

Works with grouping, too.

```ruby
Order.group("date_trunc('week', created_at)").median(:total)
```

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'active_median'
```

And create a migration to add the `median` function to the database.

```sh
rails g migration create_median_function
```

with:

```ruby
def up
  ActiveMedian.create_function
end

def down
  ActiveMedian.drop_function
end
```

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_median/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_median/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
