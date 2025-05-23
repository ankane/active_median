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

[![Build Status](https://github.com/ankane/active_median/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/active_median/actions)

## Getting Started

Add this line to your application’s Gemfile:

```ruby
gem "active_median"
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

## History

View the [changelog](https://github.com/ankane/active_median/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_median/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_median/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/active_median.git
cd active_median
bundle install

# Postgres
createdb active_median_test
bundle exec rake test

# SQLite
ADAPTER=sqlite3 BUNDLE_GEMFILE=gemfiles/sqlite3.gemfile bundle exec rake test

# MariaDB and MySQL (for MySQL, install the extension first)
mysqladmin create active_median_test
ADAPTER=mysql2 BUNDLE_GEMFILE=gemfiles/mysql2.gemfile bundle exec rake test

# SQL Server
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=YourStrong!Passw0rd' -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
docker exec -it <container-id> /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P YourStrong\!Passw0rd -C -Q "CREATE DATABASE active_median_test"
ADAPTER=sqlserver BUNDLE_GEMFILE=gemfiles/sqlserver.gemfile bundle exec rake test

# MongoDB
BUNDLE_GEMFILE=gemfiles/mongoid7.gemfile bundle exec rake test
```
