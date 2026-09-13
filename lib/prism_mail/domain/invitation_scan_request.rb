# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "time"

module PrismMail
  module Domain
    class InvitationScanRequest
      attr_reader :mailbox_id, :since, :before

      def initialize(mailbox_id:, since:, before:)
        @mailbox_id = mailbox_identifier(mailbox_id)
        @since = parse_time(since)
        @before = parse_time(before)
        raise InvalidInput, "since must precede before" unless @since < @before

        freeze
      rescue ArgumentError, TypeError
        raise InvalidInput, "timestamps must be ISO 8601", cause: nil
      end

      private

      def mailbox_identifier(value)
        unless value.is_a?(String) && value.match?(/\A[^[:cntrl:]\s]{1,100}\z/)
          raise InvalidInput, "mailbox_id must be a nonblank identifier"
        end

        value.dup.freeze
      end

      def parse_time(value)
        unless value.is_a?(String) && value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
          raise InvalidInput, "timestamps require an explicit UTC offset"
        end

        Time.iso8601(value).utc.freeze
      end
    end
  end
end
