# ActiveMedian

Median for ActiveRecord

PostgreSQL only, as MySQL only supports [aggregate user-defined functions](https://dev.mysql.com/doc/refman/8.0/en/adding-udf.html) in C and C++, and SQLite only supports them in C

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

Rails can’t store functions in `schema.rb`, so add to your `Rakefile`:

```ruby
Rake::Task["db:schema:load"].enhance do
  ActiveMedian.create_function
end
```

Or change the dump format to `sql` in `config/application.rb`:

```ruby
config.active_record.schema_format = :sql
```

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_median/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_median/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
