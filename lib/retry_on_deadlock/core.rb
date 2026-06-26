module RetryOnDeadlock
  WAIT_TIMES = [0, 1, 2, 4, 8, 16, 32]

  # Helper method to determine if retry should be attempted
  def should_retry?(kwargs)
    kwargs[:retry_on_deadlock] != false && (RetryOnDeadlock.configuration.always_retry || kwargs[:retry_on_deadlock])
  end

  # Retries a transaction if a deadlock is detected.
  # @param [Array] args Arguments passed to the transaction.
  # @param [Hash] kwargs Keyword arguments, including `retry_on_deadlock`.
  # @param [Proc] block The block to execute within the transaction.
  def transaction(*args, **kwargs, &block)
    if should_retry?(kwargs)
      transaction_with_lock_handling(*args, **kwargs.merge(retry_count: 0), &block)
    else
      super(*args, **kwargs.except(:retry_on_deadlock, :max_retries), &block)
    end
  end

  private

  # Safely retries the transaction in case of a deadlock.
  # @param [Array] args Arguments passed to the transaction.
  # @param [Hash] kwargs Keyword arguments, including `retry_count`.
  # @param [Proc] block The block to execute within the transaction.
  def transaction_with_lock_handling(*args, **kwargs, &block)
    retry_count = kwargs[:retry_count]
    max_retries = kwargs.key?(:max_retries) ? kwargs[:max_retries] : RetryOnDeadlock.configuration.max_retries

    loop do
      begin
        return transaction(*args, **kwargs.except(:retry_count, :max_retries).merge(retry_on_deadlock: false), &block)
      rescue ActiveRecord::Deadlocked => error
        raise error if inner_transaction?
        raise error if retry_count >= max_retries

        log_details(error, retry_count) if RetryOnDeadlock.configuration.enable_logging
        retry_count += 1
        exponential_backoff(retry_count)
      end
    end
  end

  # Implements exponential backoff based on the retry count.
  # @param [Integer] count The current retry count.
  def exponential_backoff(count)
    sec = WAIT_TIMES[count - 1] || WAIT_TIMES.max
    sleep(sec) if sec != 0
  end

  # Checks if the current transaction is nested.
  # @return [Boolean] True if the transaction is nested, false otherwise.
  def inner_transaction?
    connection.open_transactions != 0
  end

  # Logs details about the deadlock and retry attempt.
  # @param [Exception] exception The exception that triggered the retry.
  # @param [Integer] retry_count The current retry count.
  def log_details(exception, retry_count)
    if RetryOnDeadlock.configuration.logger
      log_level = RetryOnDeadlock.configuration.log_level
      message = <<~TXT
        RetryOnDeadlock: retry triggered, count #{retry_count}
        #{exception.message}
      TXT
      RetryOnDeadlock.configuration.logger.send(log_level, message)
    end
  end
end