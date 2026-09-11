# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "test_helper"

class DigestTest < Minitest::Test
  def request(**overrides)
    PrismMail::Domain::DigestRequest.new(mailbox_id: "box", since: "2026-09-10T00:00:00Z",
                                         before: "2026-09-11T00:00:00Z", **overrides)
  end

  def evidence(id: "one", at: "2026-09-10T12:00:00Z", **overrides)
    PrismMail::Domain::Evidence.new(id: id, mailbox_id: "box", subject: "Subject", sender: "a@example.test",
                                    excerpt: "Sensitive excerpt", received_at: at, **overrides)
  end

  def build(items, **)
    source = Object.new
    source.define_singleton_method(:read) { |**| items }
    PrismMail::Application::BuildDigest.new(source: source).call(request: request(**))
  end

  def test_half_open_window_and_deduplication
    items = [evidence, evidence, evidence(id: "start", at: "2026-09-10T00:00:00Z"),
             evidence(id: "end", at: "2026-09-11T00:00:00Z"), evidence(id: "old", at: "2026-09-09T23:59:59Z")]
    result = build(items).to_h
    assert_equal 2, result[:matched_count]
    assert_equal(%w[one start], result[:entries].map { |entry| entry[:evidence][:id] })
    assert_equal "extractive", result[:mode]
  end

  def test_deterministic_ties_and_visible_omission
    result = build([evidence(id: "z"), evidence(id: "a")], limit: 1).to_h
    assert_equal "a", result[:entries].first[:evidence][:id]
    assert_equal 1, result[:omitted_count]
  end

  def test_rejects_cross_mailbox_data_and_conflicting_duplicates
    assert_raises(PrismMail::InvalidResponse) { build([evidence(mailbox_id: "other")]) }
    assert_raises(PrismMail::InvalidResponse) { build([evidence, evidence(subject: "different")]) }
  end

  def test_empty_is_a_successful_artifact
    assert_empty build([]).to_h[:entries]
  end

  def test_source_failure_is_not_an_empty_digest
    source = Object.new
    source.define_singleton_method(:read) { |**| raise PrismMail::AccessDenied }
    assert_raises(PrismMail::AccessDenied) do
      PrismMail::Application::BuildDigest.new(source: source).call(request: request)
    end
  end

  def test_invalid_request
    assert_raises(PrismMail::InvalidInput) { request(limit: 0) }
    assert_raises(PrismMail::InvalidInput) { request(limit: 1.5) }
    assert_raises(PrismMail::InvalidInput) { request(since: "tomorrow") }
    assert_raises(PrismMail::InvalidInput) { request(since: "2026-09-12T00:00:00Z") }
    assert_raises(PrismMail::InvalidInput) { request(mailbox_id: " ") }
  end

  def test_timestamps_require_offsets_and_normalize_to_utc
    assert_raises(PrismMail::InvalidInput) { request(since: "2026-09-10T00:00:00") }
    assert_raises(PrismMail::InvalidResponse) { evidence(at: "2026-09-10T12:00:00") }
    assert_equal evidence.received_at, evidence(at: "2026-09-10T15:00:00+03:00").received_at
  end

  def test_evidence_is_minimized_immutable_and_redacted
    item = evidence(excerpt: "x" * 3000)
    assert_equal 2000, item.excerpt.length
    assert_predicate item, :frozen?
    assert_predicate item.excerpt, :frozen?
    refute_includes item.inspect, item.excerpt
    refute_includes build([item]).inspect, item.excerpt
    assert_raises(PrismMail::InvalidResponse) { evidence(at: nil) }
  end
end
