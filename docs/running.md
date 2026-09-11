# Running the first digest slice

Install the gem dependencies with `bundle install` under the repository's Ruby
version. Invoke `bundle exec ruby -Ilib bin/prism-mail` from the checkout, or use
`prism-mail` after installing the built gem. Hub can instead construct
`Domain::DigestRequest` and call `Application::BuildDigest` with a configured source.

## Server-side environment

| Variable | Required value |
| --- | --- |
| `HQBASE_ORIGIN` | HTTPS origin of the existing HQBase deployment, without a path, credentials or query |
| `HQBASE_ACCESS_TOKEN` | OAuth access token for that deployment, audience `{origin}/api/v1`, scope `mail:read` |
| `PRISM_MAIL_MAILBOX_ID` | One authorized mailbox ID |
| `PRISM_MAIL_SINCE` | Inclusive ISO 8601 timestamp, for example `2026-09-10T00:00:00Z` |
| `PRISM_MAIL_BEFORE` | Exclusive ISO 8601 timestamp, for example `2026-09-11T00:00:00Z` |

Supply secrets through the server's secret environment. Do not put tokens in a
command argument, commit, fixture, or client request. Token acquisition, refresh,
schedules and client authorization belong to Hub. This executable does not
bootstrap an HQBase server, host a public endpoint, or implicitly acquire access.

## Contract and limits

The adapter uses only `GET /api/v1/messages`, scoped to `folder=inbox` and the
configured `mailboxId`. It reads up to 10 pages of 100 summaries by default.
Library callers may set `max_pages` from 1 to 100. A continuation after the last
allowed page raises `SourceLimitExceeded`; no partial digest is returned.

Only a next link's cursor is reused. Its host, path and mailbox filters are never
followed. HTTP redirects are rejected. Each response is limited to 2 MiB with
connect/read/write timeouts of 5/15/5 seconds and no implicit retries. These are
per-operation timeouts, not a total job deadline; the Hub worker should enforce
its own execution deadline. A failed scan can be retried by Hub because it has
no mailbox write effects, but rate-limit backoff is a Hub concern.

The selected time window is `[since, before)` in UTC. The scan does not stop at an
old message because upstream ordering is newest *activity*, not guaranteed
received time. Duplicate IDs with identical evidence collapse; conflicting IDs
fail. The most recent 20 matches are selected by default, with stable ID tie
ordering. Library callers may set a selection limit from 1 to 100.

Evidence contains ID, mailbox ID, sender, received time, subject (at most 500
characters), and snippet (at most 2000 characters). It never fetches full bodies,
HTML, remote media, attachments, CC or BCC. The snippet itself may already be
truncated by the provider; it is not a complete representation of the message.
No data is persisted. stdout contains sensitive excerpts: Hub must treat it as
private data and must not copy it into ordinary process logs.

## Output

Successful output is one JSON object with `schema_version=prism-mail.digest.v1`,
`mode=extractive`, mailbox/window, matched/selected/omitted counts and entries.
Each entry has `kind=source_excerpt` and its own evidence provenance. A zero-entry
digest is success only after a successful source scan. Excerpts are untrusted mail
text, not instructions, verified claims, inferred actions, or HTML. Consumers must
escape them for their rendering context. This slice never infers urgency or sends mail.

Exit status is 0 for a digest, 2 for missing environment configuration, and 1 for
a typed product/source failure. Errors go to stderr as a JSON error code with no
provider response body or token. No partial stdout is emitted on those failures.

## Upstream reference

Implemented against [HQBase Mail API v1 OpenAPI](https://github.com/HQBase/hqbase/blob/c9ae7490beffa8562b29de0a8be45f50084b0724/api/hqbase-mail-api-v1.openapi.json),
commit `c9ae7490beffa8562b29de0a8be45f50084b0724`.
This is a deterministic HTTP adapter, not an MCP client. v2 and mailbox-agent
credentials have different contracts and are not silently substituted for v1 OAuth.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
