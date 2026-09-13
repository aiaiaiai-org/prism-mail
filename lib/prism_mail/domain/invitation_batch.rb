# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Domain
    class InvitationBatch
      attr_reader :request, :invitations, :scanned_count

      def initialize(request:, invitations:, scanned_count:)
        @request = request
        @invitations = invitations.dup.freeze
        @scanned_count = scanned_count
        freeze
      end

      def to_h
        {
          schema_version: "prism-mail.invitation-batch.v1",
          mode: "deterministic",
          mailbox_id: request.mailbox_id,
          window: { since: request.since.iso8601, before: request.before.iso8601 },
          scanned_count: scanned_count,
          invitation_count: invitations.length,
          invitations: invitations.map(&:to_h)
        }
      end

      def inspect
        "#<PrismMail::Domain::InvitationBatch [redacted]>"
      end
    end
  end
end
