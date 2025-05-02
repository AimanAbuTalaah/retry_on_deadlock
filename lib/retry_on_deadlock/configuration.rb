module RetryOnDeadlock
  class Configuration
    attr_accessor :max_retries, :logger, :enable_logging, :log_level, :always_retry

    def initialize
      @max_retries = 3
      @enable_logging = true
      @log_level = :warning
      @logger = Logger.new(STDOUT)
      @always_retry = false
    end
  end
end