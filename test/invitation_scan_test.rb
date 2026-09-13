# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "test_helper"

class InvitationScanTest < Minitest::Test
  def request(**overrides)
    PrismMail::Domain::InvitationScanRequest.new(
      mailbox_id: "box",
      since: "2026-09-13T00:00:00Z",
      before: "2026-09-14T00:00:00Z",
      **overrides
    )
  end

  def evidence(id:, subject: "Invitation to interview: iOS Engineer", sender: "jobs@upwork.com",
               at: "2026-09-13T12:00:00Z")
    PrismMail::Domain::Evidence.new(
      id: id,
      mailbox_id: "box",
      subject: subject,
      sender: sender,
      excerpt: "Open Upwork for details",
      received_at: at
    )
  end

  def scan(items, request: self.request)
    source = Object.new
    source.define_singleton_method(:read) { |**| items }
    PrismMail::Application::ScanInvitations.new(source: source).call(request: request)
  end

  def test_returns_complete_deterministic_batch_without_digest_limit
    items = 101.times.map { |index| evidence(id: format("message-%03d", index)) }
    result = scan(items).to_h

    assert_equal "prism-mail.invitation-batch.v1", result[:schema_version]
    assert_equal "deterministic", result[:mode]
    assert_equal 101, result[:scanned_count]
    assert_equal 101, result[:invitation_count]
    assert_equal 101, result[:invitations].length
    assert_equal "message-000", result[:invitations].first[:evidence_id]
    assert_equal "message-100", result[:invitations].last[:evidence_id]
  end

  def test_scans_window_but_emits_only_confirmed_invitations
    confirmed = evidence(id: "confirmed")
    ambiguous = evidence(id: "ambiguous", subject: "Weekly Upwork summary")
    old = evidence(id: "old", at: "2026-09-12T23:59:59Z")
    result = scan([ambiguous, old, confirmed]).to_h

    assert_equal 2, result[:scanned_count]
    assert_equal 1, result[:invitation_count]
    assert_equal ["confirmed"], result[:invitations].map { |item| item[:evidence_id] }
    assert_equal({ since: "2026-09-13T00:00:00Z", before: "2026-09-14T00:00:00Z" }, result[:window])
  end

  def test_deduplicates_identical_evidence_and_rejects_conflicts
    item = evidence(id: "same")
    assert_equal 1, scan([item, item]).to_h[:scanned_count]

    conflict = PrismMail::Domain::Evidence.new(
      id: "same",
      mailbox_id: "box",
      subject: "Invitation to interview: Different role",
      sender: "jobs@upwork.com",
      excerpt: "Open Upwork for details",
      received_at: "2026-09-13T12:00:00Z"
    )
    assert_raises(PrismMail::InvalidResponse) { scan([item, conflict]) }
  end

  def test_empty_window_is_a_successful_empty_batch
    result = scan([]).to_h

    assert_equal 0, result[:scanned_count]
    assert_equal 0, result[:invitation_count]
    assert_empty result[:invitations]
  end
end
