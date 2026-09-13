# `prism-mail.invitation.v1`

`prism-mail.invitation.v1` is a deterministic, extractive mail-signal artifact. It represents an invitation only when the detector can support that claim from normalized `PrismMail::Domain::Evidence`.

Required fields:

- `schema_version`: always `prism-mail.invitation.v1`;
- `evidence_id`;
- `mailbox_id`;
- `received_at`;
- `sender`;
- `subject`;
- `source_message_reference`;
- `provenance`.

Optional fields may appear only when confirmed by source evidence:

- `platform`;
- `opportunity_title`;
- `compensation`;
- `engagement_type`;
- `duration`;
- `source_url`.

Every emitted optional field must have a matching provenance entry with the evidence identifier, source field, and deterministic extraction rule. Required factual fields also carry direct provenance to their source evidence fields.

Signal detection is non-destructive. Producing an invitation artifact does not mutate the evidence, mark a message consumed, or change its eligibility for a digest. Routing, delivery, retry, and digest checkpoints remain Prism Hub responsibilities.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
