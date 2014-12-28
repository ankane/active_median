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

And add the `median` function to the database from the Rails console.

```ruby
ActiveMedian.create_function
```

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_median/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_median/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
