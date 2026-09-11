# © 2026 aiaiaiai · aiaiaiai.org

require_relative "lib/prism_mail/version"

Gem::Specification.new do |spec|
  spec.name = "aiaiaiai-prism-mail"
  spec.version = PrismMail::VERSION
  spec.authors = ["aiaiaiai"]
  spec.email = ["engineering@aiaiaiai.org"]
  spec.summary = "Calm mail intelligence for the Prism ecosystem"
  spec.homepage = "https://github.com/aiaiaiai-org/prism-mail"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 4.0", "< 4.1")
  spec.files = Dir[
    "docs/**/*",
    "lib/**/*",
    "LICENSE",
    "NOTICE",
    "README.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rubocop", "~> 1.90"
end
