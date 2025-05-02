# frozen_string_literal: true

require "retry_on_deadlock"
require "active_record"
require "logger"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure ActiveRecord to use PostgreSQL
  ActiveRecord::Base.establish_connection(
    adapter: "postgresql",
    database: "retry_on_deadlock_test",
    username: "aiman",
    password: "aiman",
    host: "localhost"
  )
 
  ActiveRecord::Base.logger = Logger.new(STDOUT)
 
  # Create a test table
  ActiveRecord::Schema.define do
    create_table :cars, force: true do |t|
      t.string :name
    end
  end
 
  # Define a test model
  class Car < ActiveRecord::Base
  end
 
  RSpec.configure do |config|
    config.before(:suite) do
      Car.delete_all
    end
  end

  RetryOnDeadlock.configure do |config|
    config.max_retries = 5
    config.enable_logging = true
    config.logger = Logger.new(STDOUT)
    config.log_level = :error
  end
end
