# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "json"

module PrismMail
  class CLI
    OPERATIONS = %w[digest invitation_scan].freeze

    def self.run(env: ENV, output: $stdout, errors: $stderr)
      artifact = build(env)
      output.puts(JSON.generate(artifact.to_h))
      0
    rescue KeyError
      errors.puts(JSON.generate(error: "configuration_missing"))
      2
    rescue Error => e
      errors.puts(JSON.generate(error: e.class.name.split("::").last))
      1
    end

    def self.build(env)
      operation = env.fetch("PRISM_MAIL_OPERATION", "digest")
      raise InvalidInput, "unsupported Prism Mail operation" unless OPERATIONS.include?(operation)

      mail_source = source(env)
      return build_digest(env, mail_source) if operation == "digest"

      scan_invitations(env, mail_source)
    end
    private_class_method :build

    def self.source(env)
      http = Adapters::HQBase::HTTP.new(
        origin: env.fetch("HQBASE_ORIGIN"), token: env.fetch("HQBASE_ACCESS_TOKEN")
      )
      Adapters::HQBase::Source.new(http: http)
    end
    private_class_method :source

    def self.build_digest(env, mail_source)
      request = Domain::DigestRequest.new(**request_attributes(env))
      Application::BuildDigest.new(source: mail_source).call(request: request)
    end
    private_class_method :build_digest

    def self.scan_invitations(env, mail_source)
      request = Domain::InvitationScanRequest.new(**request_attributes(env))
      Application::ScanInvitations.new(source: mail_source).call(request: request)
    end
    private_class_method :scan_invitations

    def self.request_attributes(env)
      {
        mailbox_id: env.fetch("PRISM_MAIL_MAILBOX_ID"),
        since: env.fetch("PRISM_MAIL_SINCE"),
        before: env.fetch("PRISM_MAIL_BEFORE")
      }
    end
    private_class_method :request_attributes
  end
end
