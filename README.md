# RetryOnDeadlock

RetryOnDeadlock is a Ruby gem designed to handle deadlocks in ActiveRecord transactions by automatically retrying them with exponential backoff. This gem is particularly useful in high-concurrency environments where deadlocks are common.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'retry_on_deadlock'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install retry_on_deadlock
```

## Usage

To use RetryOnDeadlock, simply include it in your ActiveRecord transactions. By default, the gem retries transactions up to 3 times when a deadlock occurs.

Here is an example:

```ruby
Car.transaction(retry_on_deadlock: true) do
  car = Car.find(1)
  car.update!(name: "Updated Name")
end
```

### Per-Transaction Overrides

You can override global configuration settings for a specific transaction by passing them as arguments to the `transaction` method. Currently, you can override `max_retries`:

```ruby
# Retry this specific transaction up to 5 times (overriding the global setting)
Car.transaction(retry_on_deadlock: true, max_retries: 5) do
  car = Car.find(1)
  car.update!(name: "Updated Name")
end
```

### Configuration

You can configure the gem to suit your needs. For example:

```ruby
RetryOnDeadlock.configure do |config|
  config.max_retries = 5 # Number of retries before giving up
  config.enable_logging = true # Enable logging of retry attempts
  config.log_level = :info # Log level for retry logs
  config.logger = Logger.new(STDOUT) # Custom logger
  config.always_retry = false # Always retry transactions unless explicitly disabled
end
```

### Nested Transactions

RetryOnDeadlock does not retry nested transactions. If a deadlock occurs within a nested transaction, the error will be raised immediately.

## Potential Risks

1. **Increased Database Load**:
   - Retrying transactions can increase the load on your database, especially if retries are frequent. Use with caution in high-traffic applications.

2. **Nested Transactions**:
   - The gem does not retry nested transactions. Ensure your application can handle errors in such cases.

3. **Exceeding Max Retries**:
   - If the maximum number of retries is exceeded, the original `ActiveRecord::Deadlocked` error will be raised. Make sure your application handles this scenario gracefully.

4. **Compatibility**:
   - The gem is designed for ActiveRecord and assumes a PostgreSQL database. It may not work as expected with other databases or ORMs.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run:

```bash
$ bundle exec rake install
```

To release a new version, update the version number in `version.rb`, and then run:

```bash
$ bundle exec rake release
```

This will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
