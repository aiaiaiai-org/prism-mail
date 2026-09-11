# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "time"

module PrismMail
  module Domain
    # A minimized snapshot. Provider payloads and credentials do not enter this value.
    class Evidence
      attr_reader :id, :mailbox_id, :subject, :sender, :excerpt, :received_at

      def initialize(id:, mailbox_id:, subject:, sender:, excerpt:, received_at:)
        @id = text(id, 100, required: true)
        @mailbox_id = text(mailbox_id, 100, required: true)
        @subject = text(subject, 500)
        @sender = text(sender, 320, required: true)
        @excerpt = text(excerpt, 2000)
        @received_at = Time.iso8601(received_at).utc.freeze
        freeze
      rescue ArgumentError, TypeError
        raise InvalidResponse, "invalid evidence timestamp", cause: nil
      end

      def to_h
        { id: id, mailbox_id: mailbox_id, subject: subject, sender: sender,
          excerpt: excerpt, received_at: received_at.iso8601 }
      end

      def inspect
        "#<PrismMail::Domain::Evidence [redacted]>"
      end

      private

      def validate_identity(value, limit)
        return if !value.empty? && value.length <= limit

        raise InvalidResponse, "missing evidence identity"
      end

      def text(value, limit, required: false)
        raise InvalidResponse, "invalid evidence text" unless value.is_a?(String) && value.valid_encoding?

        validate_identity(value, limit) if required

        value.gsub(/[[:cntrl:]]/, " ").strip[0, limit].freeze.tap do |result|
          raise InvalidResponse, "missing evidence identity" if required && result.empty?
        end
      end
    end
  end
end
