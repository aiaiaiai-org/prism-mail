# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Domain
    class InvitationScan
      attr_reader :request, :invitations, :scanned_count

      def initialize(request:, invitations:, scanned_count:)
        unless request.is_a?(InvitationScanRequest) && invitations.is_a?(Array) &&
               invitations.all?(Invitation) && scanned_count.is_a?(Integer) && scanned_count >= invitations.length
          raise InvalidResponse, "invalid invitation scan"
        end
        unless invitations.all? { |invitation| invitation.evidence.mailbox_id == request.mailbox_id }
          raise InvalidResponse, "invitation scan crossed mailbox boundary"
        end

        @request = request
        @invitations = invitations.dup.freeze
        @scanned_count = scanned_count
        freeze
      end

      def to_h
        {
          schema_version: "prism-mail.invitation-scan.v1",
          mode: "deterministic",
          mailbox_id: request.mailbox_id,
          window: { since: request.since.iso8601, before: request.before.iso8601 },
          scanned_count: scanned_count,
          invitation_count: invitations.length,
          invitations: invitations.map(&:to_h)
        }
      end

      def inspect
        "#<PrismMail::Domain::InvitationScan [redacted]>"
      end
    end
  end
end
