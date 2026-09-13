# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "test_helper"

class UpworkInvitationDetectorTest < Minitest::Test
  def evidence(sender: "Upwork <donotreply@upwork.com>",
               subject: "You have an invitation to interview: Senior iOS Engineer",
               excerpt: "Review: https://www.upwork.com/ab/proposals/jobdetails/123")
    PrismMail::Domain::Evidence.new(
      id: "message-1",
      mailbox_id: "box",
      subject: subject,
      sender: sender,
      excerpt: excerpt,
      received_at: "2026-09-13T03:00:00Z"
    )
  end

  def detector
    PrismMail::Signals::UpworkInvitationDetector.new
  end

  def test_emits_evidence_backed_invitation
    result = detector.call(evidence: evidence).to_h

    assert_equal "prism-mail.invitation.v1", result[:schema_version]
    assert_equal "upwork", result[:platform]
    assert_equal "Senior iOS Engineer", result[:opportunity_title]
    assert_equal "https://www.upwork.com/ab/proposals/jobdetails/123", result[:source_url]
    assert_equal "message-1", result[:source_message_reference]
    assert_equal({ evidence_id: "message-1", source_field: "sender", rule: "sender_domain" },
                 result[:provenance][:platform])
    assert_equal "subject", result[:provenance][:opportunity_title][:source_field]
    assert_equal "excerpt", result[:provenance][:source_url][:source_field]
  end

  def test_accepts_upwork_subdomain_sender
    refute_nil detector.call(evidence: evidence(sender: "notify@mail.upwork.com"))
  end

  def test_rejects_non_upwork_sender_and_spoofed_domain
    assert_nil detector.call(evidence: evidence(sender: "jobs@example.test"))
    assert_nil detector.call(evidence: evidence(sender: "jobs@upwork.com.evil.test"))
  end

  def test_rejects_non_invitation_subject
    assert_nil detector.call(evidence: evidence(subject: "Your weekly Upwork activity"))
  end

  def test_ambiguous_mail_remains_eligible_for_digest
    item = evidence(subject: "Weekly summary about invitations", excerpt: "No direct invitation signal")
    original = item.to_h

    assert_nil detector.call(evidence: item)
    assert_equal original, item.to_h

    source = Object.new
    source.define_singleton_method(:read) { |**| [item] }
    request = PrismMail::Domain::DigestRequest.new(
      mailbox_id: "box",
      since: "2026-09-13T00:00:00Z",
      before: "2026-09-14T00:00:00Z"
    )
    digest = PrismMail::Application::BuildDigest.new(source: source).call(request: request).to_h
    entry_ids = digest[:entries].map { |entry| entry[:evidence][:id] }

    assert_equal ["message-1"], entry_ids
  end

  def test_omits_unconfirmed_optional_fields
    result = detector.call(
      evidence: evidence(
        subject: "You have an invitation to interview",
        excerpt: "Open the Upwork app for details"
      )
    ).to_h

    assert_equal "upwork", result[:platform]
    refute result.key?(:opportunity_title)
    refute result.key?(:source_url)
  end

  def test_invitation_rejects_unproven_extracted_fields
    assert_raises(PrismMail::InvalidResponse) do
      PrismMail::Domain::Invitation.new(
        evidence: evidence,
        attributes: { platform: "upwork" },
        provenance: {}
      )
    end
  end
end
