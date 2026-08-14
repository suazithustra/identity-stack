---
id: "0002"
title: "Use Kratos for the human identity lifecycle"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0002: Use Kratos for the human identity lifecycle

## Context and scope

The stack needs one authority for the security-sensitive lifecycle of human
identities. That lifecycle includes identity records, credentials,
self-service identity flows, verification, recovery, and authenticated
sessions. Duplicating those responsibilities in the control plane or consuming
applications would create competing authorities and expand the credential
attack surface.

This decision concerns human identity lifecycle ownership. It does not assign
application profiles or product-domain data to Kratos, define an integration
API, choose a Kratos release, select storage topology, or decide how a user
interface presents identity flows.

## Decision drivers

- Establish one source of truth for human credentials and identity state.
- Avoid implementing security-sensitive identity flows independently in each
  consuming application.
- Keep application product data outside the identity authority.
- Preserve an upgrade boundary around an upstream identity component.

## Considered options

### Kratos owns the human identity lifecycle

Kratos provides the identity authority and established lifecycle behavior. It
reduces custom credential code and centralizes security-sensitive flows, but it
introduces an upstream dependency whose integration and upgrades require
evidence.

### Build identity lifecycle behavior in the control plane

The control plane could own credentials, recovery, verification, and sessions.
This offers direct customization, but would make the project responsible for a
large and security-critical subsystem and blur the control-plane boundary.

### Let each consuming application own identity lifecycle behavior

Applications could implement their own identities and login flows. This may
fit each product locally, but it fragments identity state, duplicates
credential risk, and makes cross-application behavior inconsistent.

## Decision and rationale

Use Kratos as the authority for the human identity lifecycle. The control plane
and consuming applications integrate with Kratos rather than becoming parallel
credential or session authorities. Product-domain records and application
profiles remain with their owning application domains unless a later accepted
decision assigns a genuinely shared concern elsewhere.

Kratos is selected because it provides the required identity boundary while
allowing the project to focus custom code on integration and shared platform
gaps instead of reimplementing credential lifecycle behavior.

## Consequences

- Credentials, identity lifecycle state, verification, recovery, and Kratos
  sessions have one upstream owner.
- Consuming applications must map their domain records to Kratos identities
  without moving product-domain data into Kratos by default.
- Integration failures and lifecycle changes require explicit contract and
  real-component testing.
- The repository must track Kratos compatibility, security advisories,
  migrations, and upgrade evidence.
- Integration API style, storage topology, release selection, and user
  experience remain open until their constraints are known.

## Reversal cost

**High.** Replacing the identity authority would affect credentials, identity
records, sessions, recovery and verification flows, application mappings, and
operational procedures. Safe reversal would require a credential and identity
migration strategy, compatibility evidence, security review, and tested
rollback or recovery behavior.

## Confirmation and fitness checks

- Architecture reviews identify Kratos as the only authority for human
  credentials and lifecycle state.
- Application and control-plane designs contain no independent password,
  recovery, verification, or session authority.
- Contract and integration evidence covers identity mappings and lifecycle
  failure behavior against the selected real Kratos release.
- Dependency inventory and upgrade records identify the exact Kratos artifact
  when a release is selected.

## Revisit triggers

- Kratos can no longer satisfy an approved human identity requirement or
  security property.
- An upstream change prevents independent, evidence-backed Kratos upgrades.
- A fitness check discovers competing credential or session authority in the
  control plane or a consuming application.
- A required migration cannot preserve identity integrity or safe recovery.

## Related ADRs

- [ADR 0001](0001-one-deployment-per-realm.md) defines the realm boundary in
  which an identity authority operates.
- [ADR 0003](0003-spicedb-application-authorization.md) separates identity
  lifecycle ownership from application authorization decisions.
- [ADR 0004](0004-elixir-control-plane.md) defines the control plane that fills
  shared integration gaps without taking over product domains.
- [ADR 0007](0007-upstream-upgrade-independence.md) governs Kratos deployment
  and upgrade independence.
