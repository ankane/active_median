## 0.3.3 (2021-08-17)

- Fixed null values for SQLite without an extension and MongoDB

## 0.3.2 (2021-08-16)

- Added support for SQLite without an extension

## 0.3.1 (2021-02-21)

- Fixed error with relations with `select` clauses

## 0.3.0 (2021-02-08)

- Added column alias
- Added support for percentiles with SQLite (switched extensions)
- Raise `ActiveRecord::UnknownAttributeReference` for non-attribute arguments
- Dropped support for Active Record < 5.2

## 0.2.8 (2021-01-16)

- Fixed bug with removing order

## 0.2.7 (2021-01-16)

- Fixed error with order

## 0.2.6 (2020-12-18)

- Fixed error with certain column types for Active Record 6.1

## 0.2.5 (2020-09-07)

- Added warning for non-attribute argument

## 0.2.4 (2020-03-12)

- Added `percentile` method

## 0.2.3 (2019-09-03)

- Added support for Mongoid
- Dropped support for Active Record 4.2

## 0.2.2 (2018-10-29)

- Added support for MySQL with udf_infusion
- Added support for SQL Server and Redshift

## 0.2.1 (2018-10-15)

- Added support for arrays and hashes
- Added compatibility with Groupdate 4

## 0.2.0 (2018-10-15)

- Added support for MariaDB 10.3.3+ and SQLite
- Use `PERCENTILE_CONT` for 4x performance increase

Breaking

- Dropped support for Postgres < 9.4

## 0.1.4 (2016-12-03)

- Added `drop_function` method

## 0.1.3 (2016-03-22)

- Added support for Active Record 5.0

## 0.1.2 (2014-12-27)

- Added support for Active Record 4.2

## 0.1.1 (2014-08-12)

- 10x faster median
- Added tests

## 0.1.0 (2014-03-13)

- First release
