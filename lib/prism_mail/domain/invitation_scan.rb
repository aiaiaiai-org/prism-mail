# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Domain
    class InvitationScan
      attr_reader :request, :invitations, :scanned_count

      def initialize(request:, invitations:, scanned_count:)
        validate_request(request)
        validate_invitations(invitations, scanned_count, request)

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

      private

      def validate_request(value)
        raise InvalidResponse, "invalid invitation scan request" unless value.is_a?(InvitationScanRequest)
      end

      def validate_invitations(value, count, current_request)
        valid = value.is_a?(Array) && value.all?(Invitation) && count.is_a?(Integer) && count >= value.length
        raise InvalidResponse, "invalid invitation scan" unless valid

        return if value.all? { |invitation| invitation.evidence.mailbox_id == current_request.mailbox_id }

        raise InvalidResponse, "invitation scan crossed mailbox boundary"
      end
    end
  end
end
