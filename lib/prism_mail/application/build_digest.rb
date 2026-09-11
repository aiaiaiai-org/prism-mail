# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Application
    class BuildDigest
      def initialize(source:)
        @source = source
      end

      def call(request:)
        seen = {}
        @source.read(mailbox_id: request.mailbox_id).each do |item|
          validate_scope(item, request)
          next unless item.received_at >= request.since && item.received_at < request.before

          add_evidence(seen, item)
        end
        compose(seen.values, request)
      end

      private

      def validate_scope(item, request)
        return if item.is_a?(Domain::Evidence) && item.mailbox_id == request.mailbox_id

        raise InvalidResponse, "source violated mailbox boundary"
      end

      def add_evidence(seen, item)
        raise InvalidResponse, "conflicting duplicate evidence" if seen.key?(item.id) && seen[item.id].to_h != item.to_h

        seen[item.id] = item
      end

      def compose(items, request)
        ordered = items.sort_by { |item| [-item.received_at.to_r, item.id] }
        Domain::Digest.new(request: request, evidence: ordered.first(request.limit), matched_count: ordered.length)
      end
    end
  end
end
