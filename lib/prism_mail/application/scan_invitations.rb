# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Application
    class ScanInvitations
      def initialize(source:, detector: Signals::UpworkInvitationDetector.new)
        @source = source
        @detector = detector
      end

      def call(request:)
        evidence = collect_evidence(request)
        invitations = evidence.filter_map { |item| @detector.call(evidence: item) }
        Domain::InvitationBatch.new(
          request: request,
          invitations: invitations,
          scanned_count: evidence.length
        )
      end

      private

      def collect_evidence(request)
        seen = {}
        @source.read(mailbox_id: request.mailbox_id).each do |item|
          validate_scope(item, request)
          next unless item.received_at >= request.since && item.received_at < request.before

          add_evidence(seen, item)
        end
        seen.values.sort_by { |item| [-item.received_at.to_r, item.id] }
      end

      def validate_scope(item, request)
        return if item.is_a?(Domain::Evidence) && item.mailbox_id == request.mailbox_id

        raise InvalidResponse, "source violated mailbox boundary"
      end

      def add_evidence(seen, item)
        raise InvalidResponse, "conflicting duplicate evidence" if seen.key?(item.id) && seen[item.id].to_h != item.to_h

        seen[item.id] = item
      end
    end
  end
end
