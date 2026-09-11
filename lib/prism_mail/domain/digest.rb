# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Domain
    # An extractive artifact, not an inference result or an instruction to deliver.
    class Digest
      attr_reader :request, :evidence, :matched_count

      def initialize(request:, evidence:, matched_count:)
        @request = request
        @evidence = evidence.dup.freeze
        @matched_count = matched_count
        freeze
      end

      def to_h
        { schema_version: "prism-mail.digest.v1", mode: "extractive",
          mailbox_id: request.mailbox_id,
          window: window,
          matched_count: matched_count, selected_count: evidence.length,
          omitted_count: matched_count - evidence.length,
          entries: evidence.map { |item| { kind: "source_excerpt", evidence: item.to_h } } }
      end

      def window
        { since: request.since.iso8601, before: request.before.iso8601 }
      end

      def inspect
        "#<PrismMail::Domain::Digest [redacted]>"
      end
    end
  end
end
