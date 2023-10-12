# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sidekiq_status/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_status"
  spec.authors       = ["Andrei Makarov"]
  spec.email         = ["andrei@kiskolabs.com"]

  spec.version       = SidekiqStatus::VERSION

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.homepage      = "https://github.com/amkisko/sidekiq_status"
  spec.summary       = "Sidekiq status web server extension."
  spec.license       = "MIT"
  spec.description   = <<~DSC
    SidekiqStatus offers a solution to add HTTP server for the sidekiq instance.
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
  spec.add_development_dependency("rubocop-shopify", "~> 2.10")
  spec.add_development_dependency("solargraph", "~> 0.49.0")

  spec.add_dependency("rack", "< 3")
  spec.add_dependency("sidekiq", ">= 5", "< 8")
  spec.add_dependency("webrick", ">= 1", "< 2")
end
