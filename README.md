# ActiveMedian

Median and percentile for Active Record, Mongoid, arrays, and hashes

Supports:

- PostgreSQL
- SQLite
- MariaDB
- MySQL (with an extension)
- SQL Server
- MongoDB

:fire: Uses native functions for blazing performance

[![Build Status](https://github.com/ankane/active_median/workflows/build/badge.svg?branch=master)](https://github.com/ankane/active_median/actions)

## Getting Started

Add this line to your application’s Gemfile:

```ruby
gem 'active_median'
```

For MySQL, also follow [these instructions](#additional-instructions).

## Models

Median

```ruby
Item.median(:price)
```

Percentile

```ruby
Request.percentile(:response_time, 0.95)
```

Works with grouping, too

```ruby
Order.group(:store_id).median(:total)
```

## Arrays and Hashes

Median

```ruby
[1, 2, 3].median
```

Percentile

```ruby
[1, 2, 3].percentile(0.95)
```

You can also pass a block

```ruby
{a: 1, b: 2, c: 3}.median { |k, v| v }
```

## Additional Instructions

### MySQL

MySQL requires the `PERCENTILE_CONT` function from [udf_infusion](https://github.com/infusion/udf_infusion). To install it, do:

```sh
git clone https://github.com/infusion/udf_infusion.git
cd udf_infusion
./configure --enable-functions="percentile_cont"
make
sudo make install
mysql <options> < load.sql
```

### SQLite

Improve performance with SQLite with an extension. Download [percentile.c](https://www.sqlite.org/src/file?name=ext/misc/percentile.c&ci=d49c32e6e7cc341b) and follow the [instructions for compiling loadable extensions](https://www.sqlite.org/loadext.html#compiling_a_loadable_extension) for your platform.

On Linux, use:

```sh
gcc -g -fPIC -shared -lsqlite3 percentile.c -o percentile.so
```

On Mac, use:

```sh
gcc -g -fPIC -dynamiclib -L/usr/local/opt/sqlite/lib -lsqlite3 percentile.c -o percentile.dylib
```

To load it in Rails, create an initializer with:

```ruby
db = ActiveRecord::Base.connection.raw_connection
db.enable_load_extension(1)
db.load_extension("percentile.so") # or percentile.dylib
db.enable_load_extension(0)
```

## Upgrading

### 0.3.0

ActiveMedian 0.3.0 protects against unsafe input by default. For non-attribute arguments, use:

```ruby
Item.median(Arel.sql(known_safe_value))
```

Also, percentiles are now supported with SQLite. Use the [percentile extension](#sqlite) instead of `extension-functions`.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_median/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_median/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development and testing:

```sh
git clone https://github.com/ankane/active_median.git
cd active_median
createdb active_median_test
bundle install
bundle exec rake test
```
