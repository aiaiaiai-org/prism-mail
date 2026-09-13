# `prism-mail.invitation-batch.v1`

`prism-mail.invitation-batch.v1` is the deterministic worker envelope used to scan one mailbox over one half-open time window for evidence-backed invitation artifacts.

Required fields:

- `schema_version`: always `prism-mail.invitation-batch.v1`;
- `mode`: always `deterministic`;
- `mailbox_id`;
- `window.since` and `window.before`;
- `scanned_count`: number of unique source messages inside the requested window;
- `invitation_count`;
- `invitations`: zero or more `prism-mail.invitation.v1` artifacts.

The batch is complete for the bounded source scan. It does not apply the digest presentation limit and never silently drops invitation artifacts. If the source cannot be scanned completely, the worker fails rather than returning a partial batch.

An empty `invitations` array is a successful scan, not a source failure. Producing a batch does not mutate source mail, advance Hub cursors, acknowledge delivery, or remove any message from future digest eligibility.

The `prism-mail` executable keeps digest generation as its default operation. Set `PRISM_MAIL_OPERATION=invitations` to request this envelope through the same read-only source credentials and mailbox/window inputs.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
