# Dependency inventory and compatibility evidence

This directory is the repository home for exact dependency identities and
reviewed compatibility results. It implements the record-keeping boundary in
the [dependency-management policy](../policies/dependency-management.md); that
policy remains the authority for pinning, update, provenance, advisory,
license, migration, and evidence requirements.

The accountable owner is the component integration maintainer for the affected
dependency. A compatibility result additionally requires an evidence reviewer
who did not rely on contributor-controlled execution to certify its own claim.
Repository automation maintainers own the workflow implementation, but they do
not replace either the component owner or evidence reviewer.

## Record ownership

| Record | Path | Accountable owner | Required boundary |
| --- | --- | --- | --- |
| Upstream component inventory | `upstream-components.md` when resolved artifacts exist | Component integration maintainer | Readable releases, immutable index and platform identities, source and publisher, provenance or explicit unavailable-evidence disposition, architecture scope, configuration profile, advisory and license review, owner, and linked evidence. |
| Local compatibility ledger | `compatibility/local-development.md` after reviewed execution exists | Component integration maintainer and evidence reviewer | One exact implementation revision, workflow or local run, configuration and fixture hashes, artifact identities, host tuple, architecture, scenarios, failures or skips, reviewer provenance, and durable evidence location. |

Do not create a blank inventory row or compatibility record to reserve either
path. A record begins only when it can name the exact artifact or observed run
it governs.

## Claim boundary

Milestone 2 may record only **local component-fixture compatibility**. That
label means the named Kratos, SpiceDB, probe, configuration, fixture, host, and
architecture tuple passed the recorded component-level scenarios. It does not
mean that the repository is authentication-ready, authorization-ready,
production-secure, durable, backup- or restore-ready, or supported on an
untested platform.

The first candidate tuple is Kratos `v26.2.0`, SpiceDB `v1.56.0`, and
`curlimages/curl` `8.21.0`. These readable versions have no support status in
this directory until their registry-specific OCI index and selected
platform-child digests, provenance dispositions, configuration hashes, and
observed results are recorded and reviewed. A different digest,
configuration, fixture, workflow, host, or architecture is unknown until new
evidence establishes otherwise.

Contributor-authored pull-request execution is input to review, not
self-attestation. A support entry must bind the tested implementation revision
to an immutable run identity and reviewer provenance. If a later evidence-only
commit records that result, it names the earlier tested revision and does not
claim that the ledger commit itself ran.

## Evidence handling

- Retain only sanitized outputs needed to reproduce or audit the conclusion.
  Never retain generated credentials, cookies, raw tokens, environment dumps,
  unredacted container inspection, or unnecessary service responses.
- Record passed, failed, and skipped gates. Missing evidence remains unknown;
  an invalidating failure remains blocked.
- Keep architecture-specific claims separate. An observed `linux/amd64` result
  does not establish `linux/arm64`, and an OCI index entry alone does not prove
  runtime compatibility.
- Link the applicable scoped
  [threat model](../security/local-development-environment-threat-model.md) and
  leave security conclusions pending while it contains an invalidating open
  item.
- Re-run evidence when an artifact identity, configuration or fixture hash,
  workflow behavior, trust boundary, or relevant advisory disposition changes.
- Preserve upstream license, notice, attribution, and source-offer obligations
  alongside the exact artifact identity.

The approved local/test orchestration boundary is recorded in
[ADR 0008](../architecture/decisions/0008-docker-compose-local-development-profile.md).
The [Milestone 2 plan](../plans/2026-08-14-0647-feat-pinned-local-development-environment-plan.md)
owns the initial evidence obligations and their delivery sequence.

