# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sidekiq_status_monitor/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_status_monitor"
  spec.authors       = ["Andrei Makarov"]
  spec.email         = ["andrei@kiskolabs.com"]

  spec.version       = SidekiqStatusMonitor::VERSION

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.homepage      = "https://github.com/amkisko/sidekiq_status_monitor"
  spec.summary       = "Rack server that outputs HTTP JSON status of sidekiq instance for alive/liveness checks and monitoring."
  spec.license       = "MIT"
  spec.description   = <<~DSC
    SidekiqStatusMonitor offers a solution to add HTTP server for the sidekiq instance.

    Can be used for Kubernetes livenessProbe and readinessProbe checks.
    Other liveness/alive checks can be done too since the server returns 200/500 status codes.

    Also provides a HTTP JSON interface for crawling metrics.
  DSC

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases",
    "documentation_uri" => "#{spec.homepage}/blob/v#{spec.version}/README.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
  }

  spec.files         = Dir["README.md", "lib/**/*"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency("bundler", "> 1.16")
  spec.add_development_dependency("debug", "~> 1.6")
  spec.add_development_dependency("rack-test", "~> 2.1.0")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("rspec-sidekiq", "~> 4.0")
  spec.add_development_dependency("solargraph", "~> 0.49.0")
  spec.add_development_dependency("standard", "~> 1")
  spec.add_development_dependency("standard-performance", "~> 1")
  spec.add_development_dependency("standard-rspec", "~> 0.2")

  spec.add_dependency("sidekiq", ">= 5", "< 8")
  spec.add_dependency("webrick", ">= 1", "< 2")
end
