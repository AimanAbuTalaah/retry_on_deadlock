# frozen_string_literal: true

require_relative "lib/retry_on_deadlock/version"
# Gem::Specification.new do |spec|
#   spec.name          = "deadlock_retry"
#   spec.version       = "0.1.0"
#   spec.authors       = ["Your Name"]
#   spec.email         = ["your.email@example.com"]

#   spec.summary       = "Automatically retry ActiveRecord transactions on deadlocks."
#   spec.description   = "A gem to handle deadlocks in ActiveRecord by retrying transactions and logging details."
#   spec.homepage      = "https://github.com/yourusername/deadlock_retry"
#   spec.license       = "MIT"

#   spec.files         = Dir["lib/**/*", "README.md", "LICENSE.txt"]
#   spec.require_paths = ["lib"]

#   spec.add_dependency "activerecord", ">= 5.0"
#   spec.add_dependency "activesupport", ">= 5.0"

#   spec.add_development_dependency "rspec", "~> 3.0"
#   spec.add_development_dependency "pg", "~> 1.0"
#   spec.add_development_dependency "pry", "~> 0.13"
# end
Gem::Specification.new do |spec|
  spec.name = "retry_on_deadlock"
  spec.version = RetryOnDeadlock::VERSION
  spec.authors = ["Aiman Abu Talaah"]
  spec.email = ["aiman.abutalaah@gmail.com"]

  spec.summary       = "Automatically retry ActiveRecord transactions on deadlocks."
  spec.description   = "A gem to handle deadlocks in ActiveRecord by retrying transactions and logging details."
  spec.homepage      = "https://github.com/yourusername/deadlock_retry"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = "https://github.com/AimanAbuTalaah/retry_on_deadlock"
  spec.metadata["source_code_uri"] = "https://github.com/AimanAbuTalaah/retry_on_deadlock"
  spec.metadata["changelog_uri"] = "https://github.com/AimanAbuTalaah/retry_on_deadlock"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", "~> 5.0"
  spec.add_runtime_dependency "activesupport", "~> 5.0"

  spec.add_development_dependency "byebug", "~> 11.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pg", "~> 1.0"
  spec.add_development_dependency "pry", "~> 0.13"
end
