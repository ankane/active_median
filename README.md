# ActiveMedian

Median for ActiveRecord - PostgreSQL only at the moment

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
gem "active_median"
```

And add the `median` function to the database from the Rails console.

```ruby
ActiveMedian.create_function
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
