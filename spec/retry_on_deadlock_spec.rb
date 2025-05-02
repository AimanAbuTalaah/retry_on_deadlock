# frozen_string_literal: true

RSpec.describe RetryOnDeadlock do
  let!(:record_a) { Car.create!(name: "Record A") }
  let!(:record_b) { Car.create!(name: "Record B") }

  it "retries transaction on deadlock when retry enabled" do
    mutex = Mutex.new
    condition = ConditionVariable.new
    thread1_started = false

    thread1 = Thread.new do
      Car.transaction(retry_on_deadlock: true) do
        mutex.synchronize do
          thread1_started = true
          condition.signal
        end

        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      mutex.synchronize do
        condition.wait(mutex) until thread1_started
      end

      Car.transaction(retry_on_deadlock: true) do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    thread1.join
    thread2.join

    expect(record_a.reload.name).to eq("Updated by Thread 1")
    expect(record_b.reload.name).to eq("Updated by Thread 2")
  end

  it "retries transaction on deadlock when retry always enabled" do
    allow(RetryOnDeadlock.configuration).to receive(:always_retry).and_return(true)

    mutex = Mutex.new
    condition = ConditionVariable.new
    thread1_started = false

    thread1 = Thread.new do
      Car.transaction do
        mutex.synchronize do
          thread1_started = true
          condition.signal
        end

        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      mutex.synchronize do
        condition.wait(mutex) until thread1_started
      end

      Car.transaction do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    thread1.join
    thread2.join

    expect(record_a.reload.name).to eq("Updated by Thread 1")
    expect(record_b.reload.name).to eq("Updated by Thread 2")
  end

  it "raise an error when deadlock retry disabled" do
    thread1 = Thread.new do
      Car.transaction(retry_on_deadlock: false) do
        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      Car.transaction(retry_on_deadlock: false) do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    expect do
      thread1.join
      thread2.join
    end.to(raise_error(ActiveRecord::Deadlocked))
  end

  it "raise an error when passing retry false even if always retry enabled" do
    allow(RetryOnDeadlock.configuration).to receive(:always_retry).and_return(true)

    thread1 = Thread.new do
      Car.transaction(retry_on_deadlock: false) do
        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      Car.transaction(retry_on_deadlock: false) do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    expect do
      thread1.join
      thread2.join
    end.to(raise_error(ActiveRecord::Deadlocked))
  end

  it "logs deadlock details" do
    logger = double("Logger")
    allow(logger).to receive(:info)
    allow(RetryOnDeadlock.configuration).to receive(:logger).and_return(logger)
    allow(RetryOnDeadlock.configuration).to receive(:enable_logging).and_return(true)
    allow(RetryOnDeadlock.configuration).to receive(:log_level).and_return(:info)

    allow_any_instance_of(ActiveRecord::Base).to receive(:transaction).and_raise(ActiveRecord::Deadlocked)

    allow(RetryOnDeadlock.configuration).to receive(:always_retry).and_return(true)

    mutex = Mutex.new
    condition = ConditionVariable.new
    thread1_started = false

    thread1 = Thread.new do
      Car.transaction do
        mutex.synchronize do
          thread1_started = true
          condition.signal
        end

        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      mutex.synchronize do
        condition.wait(mutex) until thread1_started
      end

      Car.transaction do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    thread1.join
    thread2.join

    expect(logger).to have_received(:info).with(/RetryOnDeadlock: retry triggered, count \d+/)
  end

  it "raises an error after exceeding max retries" do
    allow(RetryOnDeadlock.configuration).to receive(:max_retries).and_return(0)

    mutex = Mutex.new
    condition = ConditionVariable.new
    thread1_started = false

    mutex = Mutex.new
    condition = ConditionVariable.new
    thread1_started = false

    thread1 = Thread.new do
      Car.transaction(retry_on_deadlock: true) do
        mutex.synchronize do
          thread1_started = true
          condition.signal
        end

        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      mutex.synchronize do
        condition.wait(mutex) until thread1_started
      end

      Car.transaction(retry_on_deadlock: true) do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    expect do
      thread1.join
      thread2.join
    end.to raise_error(ActiveRecord::Deadlocked)
  end

  it "does not retry nested transactions" do
    allow(RetryOnDeadlock.configuration).to receive(:max_retries).and_return(3)

    expect do
      Car.transaction(retry_on_deadlock: true) do
        Car.transaction(retry_on_deadlock: true) do
          record_a.update!(name: "Updated by Outer Transaction")
          raise ActiveRecord::Deadlocked
        end
      end
    end.to raise_error(ActiveRecord::Deadlocked)
  end

  it "logs with the configured log level" do
    allow(RetryOnDeadlock.configuration).to receive(:enable_logging).and_return(true)
    allow(RetryOnDeadlock.configuration).to receive(:log_level).and_return(:warn)
    logger = double("Logger")
    allow(logger).to receive(:warn)
    allow(RetryOnDeadlock.configuration).to receive(:logger).and_return(logger)

    allow_any_instance_of(ActiveRecord::Base).to receive(:transaction).and_raise(ActiveRecord::Deadlocked)

    allow(RetryOnDeadlock.configuration).to receive(:always_retry).and_return(true)

    mutex = Mutex.new
    condition = ConditionVariable.new
    thread1_started = false

    thread1 = Thread.new do
      Car.transaction do
        mutex.synchronize do
          thread1_started = true
          condition.signal
        end

        record_a.update!(name: "Updated by Thread 1")
        sleep(1)
        record_b.lock!
      end
    end

    thread2 = Thread.new do
      mutex.synchronize do
        condition.wait(mutex) until thread1_started
      end

      Car.transaction do
        record_b.update!(name: "Updated by Thread 2")
        sleep(1)
        record_a.lock!
      end
    end

    thread1.join
    thread2.join

    expect(logger).to have_received(:warn).with(/retry triggered, count \d+/)
  end
end