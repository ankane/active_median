# ActiveMedian

Median for ActiveRecord

Supports PostgreSQL 9.4+ and MariaDB 10.3.3+

[![Build Status](https://travis-ci.org/ankane/active_median.svg)](https://travis-ci.org/ankane/active_median)

## Usage

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

## Upgrading

### 0.2.0

A native database function is no longer needed. Create a migration with `ActiveMedian.drop_function` to remove it.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_median/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_median/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
