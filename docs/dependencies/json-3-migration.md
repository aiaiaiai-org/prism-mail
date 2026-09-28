# Prism Mail: JSON 3.x dependency update

Status: review note for [PR #7](https://github.com/aiaiaiai-org/prism-mail/pull/7)  
Repository: `aiaiaiai-org/prism-mail`  
Date: 2026-09-28

## What is changing

Dependabot proposes changing the gem dependency in `prism-mail.gemspec` from:

```ruby
spec.add_dependency "json", ">= 2.9", "< 3"
```

to:

```ruby
spec.add_dependency "json", ">= 2.9", "< 4"
```

The current PR resolves the dependency to `json 3.0.2`.

This is a **major-version dependency update**, not an application feature change. The Prism Mail source code is not modified by PR #7.

## Why this matters

The `json` 3.0 release changed several APIs and defaults. In particular:

- `JSON.load` and `JSON.dump` no longer rely on the old insecure `create_additions` behavior.
- Mutable default-option APIs such as `JSON.load_default_options` and `JSON.dump_default_options` were removed.
- Unknown options now raise `ArgumentError` instead of being silently ignored.
- Duplicate JSON object keys are rejected by default.
- JavaScript-style comments are no longer accepted by default.
- Several rarely used aliases were removed, including `JSON.unparse`, `JSON.fast_generate`, `JSON.fast_unparse`, `JSON.pretty_unparse`, and `JSON.restore`.
- The positional `limit` argument of `JSON.dump` was removed in 3.0 and restored in 3.0.1.

PR #7 uses `json 3.0.2`, so the 3.0.1 restoration of the `JSON.dump` positional limit is already included.

## Why Prism Mail is a relatively low-risk candidate

The gemspec declares:

```ruby
spec.required_ruby_version = Gem::Requirement.new(">= 4.0", "< 4.1")
```

The project therefore does not need to preserve compatibility with the Ruby 2.7 runtimes mentioned in the `json 3.0.2` changelog.

The dependency change itself is only one line. The important question is whether Prism Mail calls any removed or behavior-sensitive JSON APIs.

## Review checklist

Before merging PR #7, verify the repository for:

- `JSON.unparse`
- `JSON.fast_generate`
- `JSON.fast_unparse`
- `JSON.pretty_unparse`
- `JSON.restore`
- `JSON.load_default_options`
- `JSON.unsafe_load_default_options`
- `JSON.dump_default_options`
- `JSON::State#[]`
- `JSON::State#[]=`
- `create_additions:`
- `allow_comments:`
- `allow_duplicate_key:`
- calls that depend on unknown/ignored JSON keyword options
- code that intentionally accepts duplicate object keys or JavaScript comments

Also run the project's normal verification suite:

```bash
bundle install
bundle exec rubocop
bundle exec rake test
bundle exec rake check
```

## Current PR state

PR #7 is:

- Open
- Not a draft
- Mergeable
- Authored by `dependabot[bot]`
- One file changed
- One line added / one line removed
- No application source changes
- CI reported as passing in the ecosystem monitoring check

No merge is performed by this document.

## Decision boundary

This document does **not** recommend blindly merging the dependency update.

The technical decision is:

1. Confirm that Prism Mail does not use removed `json 3.x` APIs or rely on changed defaults.
2. Confirm the complete CI suite passes with `json 3.0.2`.
3. If both are true, PR #7 is a routine dependency upgrade with no expected product-level behavior change.
4. If incompatible API usage is found, update that usage in a separate code change or in the dependency PR, then rerun CI.

## Relationship to Prism

This dependency is local to `prism-mail`. It does not change the Prism Hub delivery contract, Prism control-plane responsibilities, or client-facing delivery paths.

The change should therefore be treated as a **Prism Mail runtime/dependency concern**, not as a Prism protocol or ecosystem contract change.

---

Source: Dependabot PR #7 and the `json 3.0.0–3.0.2` release notes included in that PR.
