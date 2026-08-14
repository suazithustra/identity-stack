---
id: "0007"
title: "Keep upstream components independently upgradeable"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0007: Keep upstream components independently upgradeable

## Context and scope

The stack depends on focused upstream services, including Kratos and SpiceDB
and, in deployments that need it, Hydra. Project changes must not turn those
components into vendored source or a lockstep internal distribution. At the
same time, an unpinned branch or mutable reference cannot provide a reproducible
or reviewable production artifact.

This decision establishes source, deployment, pinning, and upgrade boundaries.
It does not select component releases, container runtimes, compatibility tuples,
deployment packaging, or an update schedule.

## Decision drivers

- Preserve the ability to upgrade each upstream component without modifying
  project-owned source in lockstep.
- Make deployed artifacts reproducible and auditable.
- Keep upstream security fixes and release history consumable.
- Require compatibility claims to be backed by evidence for the exact deployed
  tuple.
- Avoid carrying an indefinite private fork or patched vendor tree.

## Considered options

### Separately deploy unmodified, pinned upstream components

Each component remains an upstream artifact with an exact release or immutable
digest and its own evidence-backed upgrade path. This preserves provenance and
independence, but requires compatibility records, migration rehearsal, and
disciplined promotion.

### Vendor or patch upstream source

The repository could copy or fork component source to make local changes. This
offers immediate control, but creates a private maintenance line, complicates
security updates and attribution, and couples project releases to upstream
internals.

### Track a moving main branch or mutable image reference

Deployments could consume the latest upstream branch or mutable tag. This
reduces deliberate update work, but makes builds non-reproducible and permits
untested changes to enter production without a reviewable compatibility tuple.

### Upgrade all components as one locked bundle

The project could release only a single fixed stack tuple. This can simplify a
single tested snapshot, but prevents independent security and maintenance
updates and increases the blast radius of every component change.

## Decision and rationale

Deploy upstream components separately and without project-owned source
modifications. Pin every production artifact to an exact upstream release or
immutable image digest; a readable tag may accompany a digest but does not
replace it. Production must never track a moving main branch or depend on a
mutable-only artifact reference.

Maintain independent upgrade procedures for each component. An independent
upgrade still requires compatibility, contract, integration, migration, and
rollback or restore evidence for the resulting stack tuple; independence does
not mean untested substitution.

## Consequences

- Kratos, SpiceDB, and optional Hydra retain clear upstream provenance and can
  receive focused security or maintenance upgrades.
- The project must maintain an exact component inventory and evidence for each
  supported compatibility tuple once versions are selected.
- Upstream license, notice, and attribution obligations remain visible for the
  artifacts the project distributes or deploys.
- Local requirements must be met through supported configuration and external
  integration boundaries, or be taken upstream, rather than through a hidden
  patch set.
- Some upgrades may remain blocked until migrations, contracts, or rollback
  behavior are proven; no compatibility is implied before that evidence exists.

## Reversal cost

**High.** Moving to vendored or lockstep components would change source
ownership, release engineering, vulnerability response, attribution,
deployment, and upgrade procedures. Safe reversal would require a maintained
fork strategy, security-update service level, provenance controls, migration
evidence, and an explicit reason that supported upstream boundaries cannot meet
the approved requirement.

## Confirmation and fitness checks

- Deployment inventories identify each upstream component by exact release or
  immutable digest and contain no moving main branch or mutable-only production
  reference.
- Repository inventory contains configuration and integration code, not
  vendored or patched upstream source.
- Each component upgrade has contract and real-component integration evidence,
  compatibility results for the resulting tuple, migration rehearsal when
  applicable, and rollback or restore disposition.
- Upgrade records show that one upstream component can be evaluated and
  promoted without requiring an unrelated project-owned source release.
- Dependency review records applicable upstream license, notice, attribution,
  and security-advisory handling.

## Revisit triggers

- A required capability cannot be achieved through supported upstream
  configuration or integration boundaries and upstream contribution is not
  viable.
- Upstream maintenance or licensing changes make unmodified consumption unsafe
  or impossible.
- Compatibility evidence shows that nominally independent upgrades always
  require a coordinated stack release.
- An inventory finds a moving branch, mutable-only production reference,
  unrecorded patch, or vendored upstream source.

## Related ADRs

- [ADR 0002](0002-kratos-identity-lifecycle.md) selects Kratos as an upstream
  identity authority.
- [ADR 0003](0003-spicedb-application-authorization.md) selects SpiceDB as an
  upstream authorization authority.
- [ADR 0004](0004-elixir-control-plane.md) keeps project-owned behavior outside
  upstream source.
- [ADR 0005](0005-optional-hydra-profile.md) applies this upgrade boundary when
  Hydra is enabled.
