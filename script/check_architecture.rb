#!/usr/bin/env ruby
# © 2026 aiaiaiai · aiaiaiai.org

ROOT = File.expand_path("..", __dir__)
PROTECTED_ROOTS = %w[domain application ports].freeze
VENDOR_TERMS = %w[
  anthropic
  elevenlabs
  gemini
  gmail
  hqbase
  matrix
  openai
  proton
  telegram
].freeze
NETWORK_REQUIRES = ["net/http", "open-uri"].freeze

violations = []

PROTECTED_ROOTS.each do |root_name|
  root = File.join(ROOT, "lib/prism_mail", root_name)
  next unless Dir.exist?(root)

  Dir[File.join(root, "**/*.rb")].each do |path|
    source = File.read(path)
    relative = path.delete_prefix("#{ROOT}/")

    VENDOR_TERMS.each do |term|
      next unless source.match?(/\b#{Regexp.escape(term)}\b/i)

      violations << "#{relative}: product core must not name vendor/client term #{term.inspect}"
    end

    NETWORK_REQUIRES.each do |library|
      next unless source.include?("require \"#{library}\"") || source.include?("require '#{library}'")

      violations << "#{relative}: network library #{library.inspect} belongs behind an adapter"
    end
  end
end

if violations.empty?
  puts "architecture: ok"
  exit 0
end

warn violations.join("\n")
exit 1
