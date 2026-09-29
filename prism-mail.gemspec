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
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.files = Dir[
    "docs/**/*",
    "bin/*",
    "lib/**/*",
    "LICENSE",
    "NOTICE",
    "README.md"
  ]
  spec.bindir = "bin"
  spec.executables = ["prism-mail"]
  spec.add_dependency "json", ">= 2.9", "< 4"
  spec.add_dependency "net-http", ">= 0.6", "< 1"
  spec.add_dependency "time", ">= 0.4", "< 1"
  spec.require_paths = ["lib"]
end
