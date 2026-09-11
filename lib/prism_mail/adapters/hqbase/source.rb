# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Adapters
    module HQBase
      class Source < Ports::Source
        def initialize(http:, max_pages: 10)
          super()
          unless max_pages.is_a?(Integer) && (1..100).cover?(max_pages)
            raise InvalidInput, "max_pages must be from 1 to 100"
          end

          @http = http
          @max_pages = max_pages
        end

        def read(mailbox_id:)
          rows = []
          each_page(mailbox_id) do |data|
            validate_page(data)
            rows.concat(data.map { |row| normalize(row, mailbox_id) })
          end
          rows.freeze
        end

        private

        def each_page(mailbox_id)
          cursors = []
          @max_pages.times do
            response = fetch_page(mailbox_id, cursors.last)
            yield response.data
            cursor = next_cursor(response.link)
            return unless cursor
            raise InvalidResponse, "source repeated pagination cursor" if cursors.include?(cursor)

            cursors << cursor
          end
          raise SourceLimitExceeded, "source scan exceeded page budget"
        end

        def fetch_page(mailbox_id, cursor)
          parameters = { folder: "inbox", mailboxId: mailbox_id, limit: 100 }
          parameters[:cursor] = cursor if cursor
          @http.get(parameters)
        end

        def validate_page(data)
          return if data.is_a?(Array) && data.length <= 100 && data.all?(Hash)

          raise InvalidResponse, "invalid source page"
        end

        def normalize(row, mailbox_id)
          unless row.fetch("mailboxId") == mailbox_id && row.fetch("direction") == "inbound" &&
                 row.fetch("folder") == "inbox"
            raise InvalidResponse, "source returned out-of-scope evidence"
          end

          Domain::Evidence.new(id: row.fetch("id"), mailbox_id: mailbox_id, subject: row.fetch("subject"),
                               sender: row.fetch("fromAddress"), excerpt: row.fetch("snippet"),
                               received_at: row.fetch("receivedAt"))
        rescue KeyError
          raise InvalidResponse, "source evidence is incomplete", cause: nil
        end

        # Extract only the opaque cursor. Never follow a provider-supplied URL or its other filters.
        def next_cursor(link)
          return nil if link.nil? || link.empty?

          links = link.split(/,(?=\s*<)/)
          next_links = links.grep(/;\s*rel="?next"?(?:;|\s|$)/)
          return nil if next_links.empty?
          raise InvalidResponse, "ambiguous source pagination" unless next_links.length == 1

          cursor_from_link(next_links.first)
        end

        def cursor_from_link(link)
          target = link[/\A\s*<([^>]+)>/, 1]
          raise InvalidResponse, "invalid source pagination" unless target

          query = URI.parse(target).query
          cursors = URI.decode_www_form(query.to_s).filter_map { |key, value| value if key == "cursor" }
          unless cursors.length == 1 && (1..512).cover?(cursors.first.length)
            raise InvalidResponse, "invalid source cursor"
          end

          cursors.first
        rescue URI::InvalidURIError, ArgumentError
          raise InvalidResponse, "invalid source pagination", cause: nil
        end
      end
    end
  end
end
