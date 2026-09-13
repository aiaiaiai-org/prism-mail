# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "json"

module PrismMail
  class CLI
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
      source = build_source(env)
      case operation
      when "digest" then build_digest(env, source)
      when "invitations" then scan_invitations(env, source)
      else raise InvalidInput, "unsupported mail operation"
      end
    end

    def self.build_source(env)
      http = Adapters::HQBase::HTTP.new(origin: env.fetch("HQBASE_ORIGIN"), token: env.fetch("HQBASE_ACCESS_TOKEN"))
      Adapters::HQBase::Source.new(http: http)
    end

    def self.build_digest(env, source)
      request = Domain::DigestRequest.new(mailbox_id: env.fetch("PRISM_MAIL_MAILBOX_ID"),
                                          since: env.fetch("PRISM_MAIL_SINCE"), before: env.fetch("PRISM_MAIL_BEFORE"))
      Application::BuildDigest.new(source: source).call(request: request)
    end

    def self.scan_invitations(env, source)
      request = Domain::InvitationScanRequest.new(mailbox_id: env.fetch("PRISM_MAIL_MAILBOX_ID"),
                                                  since: env.fetch("PRISM_MAIL_SINCE"),
                                                  before: env.fetch("PRISM_MAIL_BEFORE"))
      Application::ScanInvitations.new(source: source).call(request: request)
    end

    private_class_method :build, :build_source, :build_digest, :scan_invitations
  end
end
