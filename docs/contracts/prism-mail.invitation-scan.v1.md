# `prism-mail.invitation-scan.v1`

`prism-mail.invitation-scan.v1` is the deterministic worker boundary used by Prism Hub to scan a bounded mailbox time window for invitation artifacts.

The artifact contains:

- `schema_version`: `prism-mail.invitation-scan.v1`;
- `mode`: `deterministic`;
- `mailbox_id`;
- a half-open `window` with `since` inclusive and `before` exclusive;
- `scanned_count`: unique source evidence items observed inside that window;
- `invitation_count`;
- `invitations`: ordered `prism-mail.invitation.v1` artifacts.

Evidence is de-duplicated by source evidence identity. Conflicting duplicates, cross-mailbox evidence, incomplete source scans, and detector ambiguity fail explicitly instead of returning partial success.

Invitations are ordered by `received_at`, then evidence identity. A successful empty `invitations` array means the requested source window was scanned successfully and no configured deterministic detector matched.

This contract does not consume, mutate, archive, or mark source mail. Producing an invitation alert therefore has no effect on later digest eligibility. Prism Hub owns scan cursors, delivery state, retries, and the decision to advance a cursor only after downstream delivery succeeds.

The one-shot executable selects this worker boundary with `PRISM_MAIL_OPERATION=invitation_scan`. The existing digest operation remains the default for backward compatibility.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
