# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "json"

module PrismMail
  class CLI
    def self.run(env: ENV, output: $stdout, errors: $stderr)
      digest = build(env)
      output.puts(JSON.generate(digest.to_h))
      0
    rescue KeyError
      errors.puts(JSON.generate(error: "configuration_missing"))
      2
    rescue Error => e
      errors.puts(JSON.generate(error: e.class.name.split("::").last))
      1
    end

    def self.build(env)
      request = Domain::DigestRequest.new(mailbox_id: env.fetch("PRISM_MAIL_MAILBOX_ID"),
                                          since: env.fetch("PRISM_MAIL_SINCE"), before: env.fetch("PRISM_MAIL_BEFORE"))
      http = Adapters::HQBase::HTTP.new(origin: env.fetch("HQBASE_ORIGIN"), token: env.fetch("HQBASE_ACCESS_TOKEN"))
      source = Adapters::HQBase::Source.new(http: http)
      Application::BuildDigest.new(source: source).call(request: request)
    end
    private_class_method :build
  end
end
