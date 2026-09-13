# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "test_helper"

class InvitationScanTest < Minitest::Test
  def request(**overrides)
    PrismMail::Domain::InvitationScanRequest.new(
      mailbox_id: "box", since: "2026-09-13T00:00:00Z", before: "2026-09-14T00:00:00Z", **overrides
    )
  end

  def evidence(id:, at:, sender: "sender@example.test", subject: "Hello", excerpt: "", **overrides)
    PrismMail::Domain::Evidence.new(
      id: id, mailbox_id: "box", sender: sender, subject: subject,
      excerpt: excerpt, received_at: at, **overrides
    )
  end

  def upwork(id:, at:, title: "Swift Engineer")
    evidence(
      id: id, at: at, sender: "Upwork <donotreply@upwork.com>",
      subject: "Invitation to interview: #{title}", excerpt: "https://www.upwork.com/jobs/#{id}"
    )
  end

  def scan(items, request_value: request)
    source = Object.new
    source.define_singleton_method(:read) do |mailbox_id:|
      raise "wrong mailbox" unless mailbox_id == "box"

      items
    end
    PrismMail::Application::ScanInvitations.new(source: source).call(request: request_value)
  end

  def test_scan_is_deterministic_complete_and_non_destructive
    items = [
      upwork(id: "later", at: "2026-09-13T12:00:00Z"),
      evidence(id: "ordinary", at: "2026-09-13T11:00:00Z"),
      upwork(id: "earlier", at: "2026-09-13T10:00:00Z"),
      upwork(id: "earlier", at: "2026-09-13T10:00:00Z"),
      upwork(id: "end", at: "2026-09-14T00:00:00Z")
    ]

    result = scan(items).to_h
    evidence_ids = result[:invitations].map { |item| item[:evidence_id] }

    assert_equal "prism-mail.invitation-scan.v1", result[:schema_version]
    assert_equal "deterministic", result[:mode]
    assert_equal 3, result[:scanned_count]
    assert_equal 2, result[:invitation_count]
    assert_equal %w[earlier later], evidence_ids
    assert_equal "box", result[:mailbox_id]
  end

  def test_scan_preserves_evidence_backed_invitation_provenance
    result = scan([upwork(id: "invite", at: "2026-09-13T10:00:00Z")]).to_h.fetch(:invitations).first

    assert_equal "upwork", result[:platform]
    assert_equal "Swift Engineer", result[:opportunity_title]
    assert_equal "https://www.upwork.com/jobs/invite", result[:source_url]
    assert_equal "sender", result.fetch(:provenance).fetch(:platform).fetch(:source_field)
    assert_equal "subject", result.fetch(:provenance).fetch(:opportunity_title).fetch(:source_field)
  end

  def test_scan_fails_on_scope_or_conflicting_duplicate_evidence
    cross_mailbox = evidence(id: "other", at: "2026-09-13T10:00:00Z", mailbox_id: "other")
    assert_raises(PrismMail::InvalidResponse) { scan([cross_mailbox]) }

    first = evidence(id: "same", at: "2026-09-13T10:00:00Z")
    changed = evidence(id: "same", at: "2026-09-13T10:00:00Z", subject: "Changed")
    assert_raises(PrismMail::InvalidResponse) { scan([first, changed]) }
  end

  def test_invalid_window_fails_before_source_use
    assert_raises(PrismMail::InvalidInput) do
      request(since: "2026-09-14T00:00:00Z", before: "2026-09-13T00:00:00Z")
    end
    assert_raises(PrismMail::InvalidInput) { request(since: "2026-09-13T00:00:00") }
    assert_raises(PrismMail::InvalidInput) { request(mailbox_id: " ") }
  end
end
