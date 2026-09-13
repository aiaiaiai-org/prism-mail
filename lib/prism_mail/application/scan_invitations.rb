# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Application
    class ScanInvitations
      def initialize(source:, detectors: [Signals::UpworkInvitationDetector.new])
        unless detectors.is_a?(Array) && !detectors.empty?
          raise InvalidInput, "at least one invitation detector is required"
        end

        @source = source
        @detectors = detectors.dup.freeze
      end

      def call(request:)
        seen = collect_evidence(request)
        ordered = seen.values.sort_by { |item| [item.received_at.to_r, item.id] }
        invitations = ordered.filter_map { |item| detect(item) }
        Domain::InvitationScan.new(request: request, invitations: invitations, scanned_count: ordered.length)
      end

      private

      def collect_evidence(request)
        seen = {}
        @source.read(mailbox_id: request.mailbox_id).each do |item|
          validate_scope(item, request)
          next unless in_window?(item, request)

          add_evidence(seen, item)
        end
        seen
      end

      def validate_scope(item, request)
        return if item.is_a?(Domain::Evidence) && item.mailbox_id == request.mailbox_id

        raise InvalidResponse, "source violated mailbox boundary"
      end

      def in_window?(item, request)
        item.received_at >= request.since && item.received_at < request.before
      end

      def add_evidence(seen, item)
        conflict = seen.key?(item.id) && seen[item.id].to_h != item.to_h
        raise InvalidResponse, "conflicting duplicate evidence" if conflict

        seen[item.id] = item
      end

      def detect(item)
        matches = @detectors.filter_map { |detector| detector.call(evidence: item) }
        raise InvalidResponse, "multiple invitation detectors matched one evidence item" if matches.length > 1

        matches.first
      end
    end
  end
end
