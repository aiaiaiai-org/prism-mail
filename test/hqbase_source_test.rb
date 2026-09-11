# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "test_helper"

class HQBaseSourceTest < Minitest::Test
  Response = PrismMail::Adapters::HQBase::HTTP::Response

  class FakeHTTP
    attr_reader :calls

    def initialize(responses)
      @responses = responses
      @calls = []
    end

    def get(parameters)
      @calls << parameters
      @responses.shift || raise("unexpected request")
    end
  end

  def row(**changes)
    { "id" => "one", "mailboxId" => "box", "direction" => "inbound", "folder" => "inbox",
      "subject" => "Example", "fromAddress" => "sender@example.test", "snippet" => "Source text",
      "receivedAt" => "2026-09-10T12:00:00Z" }.merge(changes.transform_keys(&:to_s))
  end

  def source(pages, max_pages: 10)
    @http = FakeHTTP.new(pages)
    PrismMail::Adapters::HQBase::Source.new(http: @http, max_pages: max_pages)
  end

  def test_reads_all_pages_using_only_cursor_and_original_scope
    link = '<https://hostile.test/api/v1/messages?cursor=abc%2B123&mailboxId=other>; rel="next"'
    result = source([Response.new(data: [row], link: link), Response.new(data: [])]).read(mailbox_id: "box")
    assert_equal 1, result.length
    assert_equal({ folder: "inbox", mailboxId: "box", limit: 100, cursor: "abc+123" }, @http.calls.last)
  end

  def test_rejects_cross_mailbox_and_missing_fields
    [row(mailboxId: "other"), row(receivedAt: nil), row(direction: "outbound"), {}].each do |invalid|
      assert_raises(PrismMail::InvalidResponse) do
        source([Response.new(data: [invalid])]).read(mailbox_id: "box")
      end
    end
  end

  def test_rejects_non_array_and_oversized_pages
    [{ "messages" => [] }, [row] * 101].each do |invalid|
      assert_raises(PrismMail::InvalidResponse) do
        source([Response.new(data: invalid)]).read(mailbox_id: "box")
      end
    end
  end

  def test_repeated_cursor_is_failure
    page = Response.new(data: [], link: '</api/v1/messages?cursor=same>; rel="next"')
    assert_raises(PrismMail::InvalidResponse) { source([page, page]).read(mailbox_id: "box") }
  end

  def test_scan_limit_never_returns_partial_success
    page = Response.new(data: [row], link: '</api/v1/messages?cursor=next>; rel="next"')
    assert_raises(PrismMail::SourceLimitExceeded) { source([page], max_pages: 1).read(mailbox_id: "box") }
  end

  def test_invalid_cursor_is_failure
    page = Response.new(data: [], link: '</api/v1/messages?cursor=a&cursor=b>; rel="next"')
    assert_raises(PrismMail::InvalidResponse) { source([page]).read(mailbox_id: "box") }
  end

  def test_only_https_origins_without_credentials_are_accepted
    %w[http://mail.test https://user:password@mail.test https://mail.test/path
       https://mail.test?token=x].each do |origin|
      assert_raises(PrismMail::InvalidInput) { PrismMail::Adapters::HQBase::HTTP.new(origin: origin, token: "secret") }
    end
    client = PrismMail::Adapters::HQBase::HTTP.new(origin: "https://mail.test", token: "secret")
    refute_includes client.inspect, "secret"
  end
end
