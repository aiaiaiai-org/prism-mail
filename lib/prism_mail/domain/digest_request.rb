# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "time"

module PrismMail
  module Domain
    class DigestRequest
      attr_reader :mailbox_id, :since, :before, :limit

      def initialize(mailbox_id:, since:, before:, limit: 20)
        validate_options(mailbox_id, limit)
        @mailbox_id = mailbox_id.dup.freeze
        @since = parse_time(since)
        @before = parse_time(before)
        raise InvalidInput, "since must precede before" unless @since < @before

        @limit = limit
        freeze
      rescue ArgumentError, TypeError
        raise InvalidInput, "timestamps must be ISO 8601", cause: nil
      end

      private

      def parse_time(value)
        unless value.is_a?(String) && value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
          raise InvalidInput, "timestamps require an explicit UTC offset"
        end

        Time.iso8601(value).utc.freeze
      end

      def validate_options(mailbox_id, limit)
        unless mailbox_id.is_a?(String) && mailbox_id.match?(/\A[^[:cntrl:]\s]{1,100}\z/)
          raise InvalidInput, "mailbox_id must be a nonblank identifier"
        end
        return if limit.is_a?(Integer) && (1..100).cover?(limit)

        raise InvalidInput,
              "limit must be an integer from 1 to 100"
      end
    end
  end
end
