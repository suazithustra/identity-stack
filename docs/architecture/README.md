# Architecture decisions

Architecture decision records (ADRs) capture choices that constrain the
structure, boundaries, operation, or evolution of `identity-stack`. Each record
explains one decision in enough context that a later maintainer can understand
why it was made, how to confirm that the repository still follows it, and what
observable change should cause it to be reconsidered.

This process adapts the option-oriented structure of
[MADR 4.0.0](https://github.com/adr/madr/blob/4.0.0/template/adr-template.md)
to this repository's lifecycle and evidence requirements.

## When to write an ADR

Write an ADR before implementing a choice that has durable architectural
consequences, affects more than one owned boundary, constrains security or
upgrade behavior, or would be costly to reverse. Keep decisions that depend on
unknown later-milestone constraints visibly open; an unresolved question is not
an accepted ADR.

Each ADR owns one decision. Serious alternatives and the reasons they were not
chosen belong in that record. Do not create separate rejected ADRs for the
unchosen options. A record itself uses `rejected` only when the complete
proposal was considered and not adopted.

## File and identifier rules

- Store records in `docs/architecture/decisions/`.
- Allocate the next unused four-digit numeric identifier, beginning with
  `0001`. Never renumber or reuse an identifier, including one assigned to a
  rejected record.
- Name the file `NNNN-short-kebab-case-title.md`, where `NNNN` is the
  identifier. The filename may be shortened for readability, but its identifier
  must match the record metadata and heading.
- Use `# ADR NNNN: Title` as the first heading. The title text must match the
  `title` metadata value.
- Copy [the repository template](adr-template.md) when starting a record.

Once a proposed ADR has entered version control, preserve the record even if
the proposal is rejected. Version history and the lifecycle metadata provide
the audit trail.

## Required record contract

Every ADR starts with YAML frontmatter containing these fields:

| Field | Requirement |
| --- | --- |
| `id` | The four-digit identifier as a quoted string so leading zeros are preserved. |
| `title` | A concise statement of the decision, matching the first heading. |
| `status` | One lowercase value: `proposed`, `accepted`, `rejected`, `deprecated`, or `superseded`. |
| `date` | The ISO 8601 acceptance or rejection date; `null` while the record is proposed. It remains the original decision date after a later lifecycle transition. |
| `decision-makers` | A non-empty list of accountable people or roles. |
| `supersedes` | A list of predecessor ADR identifiers, or an empty list when there are none. |
| `superseded_by` | The successor ADR identifier, or `null` when there is no successor. |

Every ADR body contains all of the following sections:

1. Context and scope.
2. Decision drivers.
3. Considered options, including meaningful benefits, drawbacks, and risks.
4. Decision and rationale.
5. Consequences, both desirable and undesirable.
6. Reversal cost, classified qualitatively as low, medium, or high and
   explained in repository terms.
7. Confirmation and fitness checks that produce observable evidence.
8. Revisit triggers stated as observable conditions rather than calendar-only
   reminders.
9. Related ADRs.

Do not remove a required section because it is brief. State that there is no
applicable content and explain why when a section genuinely has none.

## Lifecycle

Allowed status transitions are intentionally narrow:

| Current status | Allowed next status | Meaning |
| --- | --- | --- |
| `proposed` | `accepted` | The decision is adopted and becomes current. |
| `proposed` | `rejected` | The proposal as a whole is not adopted. |
| `accepted` | `deprecated` | The decision no longer applies and has no direct replacement. |
| `accepted` | `superseded` | An accepted successor replaces or materially changes the decision. |

`rejected`, `deprecated`, and `superseded` are terminal. An accepted ADR stays
current until it is explicitly deprecated or superseded; a new proposal does
not change the current decision by itself.

When a proposal becomes accepted or rejected, set `date` to the disposition
date. After a record is accepted or rejected, its title, decision date,
decision-makers, and body are immutable. Later edits are limited to lifecycle
metadata and successor links. Fixing or changing the substance requires a new
ADR so that the original context and consequences remain reviewable.

## Changing an accepted decision

Create a successor ADR when evidence or changed constraints require a material
change to an accepted decision:

1. Allocate a new identifier and write the proposed decision in a new record.
2. List the predecessor identifier in the successor's `supersedes` metadata and
   link the predecessor in the successor's Related ADRs section.
3. Keep the predecessor accepted while the successor remains proposed.
4. When the successor is accepted, change the predecessor status to
   `superseded`, set its `superseded_by` value to the successor identifier, and
   add the successor link to its Related ADRs section.
5. Leave the predecessor body unchanged except for that successor link.

Use `deprecated` only when a decision no longer applies and there is no direct
replacement. If a rejected proposal is reconsidered, create a new ADR rather
than reopening or rewriting the rejected record.

## Decision index

Keep each record in exactly one table according to its current status. Update
the index in the same change that adds a record or changes its lifecycle
metadata.

### Current accepted decisions

| ID | Decision | Date |
| --- | --- | --- |
| [0001](decisions/0001-one-deployment-per-realm.md) | Use one deployment per realm | 2026-08-14 |
| [0002](decisions/0002-kratos-identity-lifecycle.md) | Use Kratos for the human identity lifecycle | 2026-08-14 |
| [0003](decisions/0003-spicedb-application-authorization.md) | Use SpiceDB for application authorization | 2026-08-14 |
| [0004](decisions/0004-elixir-control-plane.md) | Use an Elixir modular-monolith control plane | 2026-08-14 |
| [0005](decisions/0005-optional-hydra-profile.md) | Make Hydra an optional deployment profile | 2026-08-14 |
| [0006](decisions/0006-exclude-oathkeeper-and-keto.md) | Exclude Oathkeeper and Keto | 2026-08-14 |
| [0007](decisions/0007-upstream-upgrade-independence.md) | Keep upstream components independently upgradeable | 2026-08-14 |
| [0008](decisions/0008-docker-compose-local-development-profile.md) | Use Docker Compose for the local development profile | 2026-08-14 |

### Active proposals

No proposed decisions are recorded yet.

| ID | Proposal | Decision makers |
| --- | --- | --- |

### Historical decisions

Rejected, deprecated, and superseded records appear here. A superseded row
links its successor.

No historical decisions are recorded yet.

| ID | Decision | Status | Successor |
| --- | --- | --- | --- |
