# frozen_string_literal: true
# Copyright (c) 2025 Aiman Abu Talaah. Licensed under the MIT License.

require "active_record"
require "logger"
require "retry_on_deadlock/version"
require "retry_on_deadlock/configuration"
require "retry_on_deadlock/core"
require 'byebug'

module RetryOnDeadlock
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    # Configure the gem
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end
  end
end
ActiveRecord::Base.send(:extend, RetryOnDeadlock)

