# Handoff authority map

Local handoffs preserve context between work sessions, but they are not repository authority and must never be committed. This map records where each inherited topic is governed now. If a local handoff conflicts with a tracked document, the tracked document wins.

## Settled direction

| Topic | Current authority |
| --- | --- |
| Project purpose, intended adopters, maintainer scope, success signals, and non-goals | [`STRATEGY.md`](../../STRATEGY.md) |
| Apache-2.0 for project-owned source | [`LICENSE`](../../LICENSE) and [`NOTICE`](../../NOTICE) |
| One deployment per identity realm; no built-in tenancy; organizations are not deployment isolation boundaries | [ADR 0001](../architecture/decisions/0001-one-deployment-per-realm.md) |
| Kratos ownership of human identities, credentials, sessions, and self-service identity lifecycle | [ADR 0002](../architecture/decisions/0002-kratos-identity-lifecycle.md) |
| Application-level SpiceDB authorization, shared relationship conventions, and fail-closed protected operations | [ADR 0003](../architecture/decisions/0003-spicedb-application-authorization.md) |
| Elixir control-plane responsibilities, consuming-application domain ownership, and the modular-monolith preference | [ADR 0004](../architecture/decisions/0004-elixir-control-plane.md) |
| Hydra as an optional deployment profile | [ADR 0005](../architecture/decisions/0005-optional-hydra-profile.md) |
| Exclusion of Oathkeeper and Keto, downstream domain models, and a generalized extension framework | [ADR 0006](../architecture/decisions/0006-exclude-oathkeeper-and-keto.md) and [`STRATEGY.md`](../../STRATEGY.md) |
| Upstream components remain unmodified, separately deployable, pinned, and independently upgradeable | [ADR 0007](../architecture/decisions/0007-upstream-upgrade-independence.md) and the [dependency-management policy](../policies/dependency-management.md) |
| Ownership boundaries for control-plane code, shared packages, upstream configuration, SpiceDB schemas, tests, deployment assets, runbooks, plans, security material, and ADRs | [Repository layout](../architecture/repository-layout.md) |
| Stable opaque identifiers, narrow versioned interfaces, separation of authentication and authorization, and ownership of shared relationship mutations | [Cross-boundary design principles](../architecture/repository-layout.md#cross-boundary-design-principles), with component responsibilities in [ADR 0002](../architecture/decisions/0002-kratos-identity-lifecycle.md), [ADR 0003](../architecture/decisions/0003-spicedb-application-authorization.md), and [ADR 0004](../architecture/decisions/0004-elixir-control-plane.md); later interface work may select contract shape and mechanics without reopening these constraints |
| Least privilege, deny-by-default behavior, trusted identity propagation, personal-data minimization, audit hygiene, retry-safe external workflows, and security review triggers | [Cross-boundary design principles](../architecture/repository-layout.md#cross-boundary-design-principles), [threat-modeling process](../security/threat-modeling.md), [threat-model template](../security/threat-model-template.md), [secrets-handling policy](../policies/secrets-handling.md), and [testing strategy](../policies/testing-strategy.md) |
| Required testing layers and dependency-failure coverage | [Testing strategy](../policies/testing-strategy.md) |
| Completion, review, attribution, documentation, and reusable-learning expectations | [Definition of done](definition-of-done.md) |

## Deferred capabilities

These product-level capabilities are approved direction, not Milestone 1 implementation scope. Each remains governed by [`STRATEGY.md`](../../STRATEGY.md) until an approved milestone plan and any necessary ADRs define it.

| Capability | Deferred owner |
| --- | --- |
| Application registration, stable application identifiers, and trusted origins or redirects | Application-registry milestone plan |
| Application accounts, application-specific profile state, shared attributes, and downstream projections | Application-account and profile milestone plan |
| Organizations, memberships, invitations, lifecycle states, and organization roles | Organization milestone plan |
| Safe identity, application, organization, membership, and access administration | Administration milestone plan |
| Security-relevant and administrative audit records, retention, integrity, redaction, export, and access | Audit milestone plan |
| Privacy inventory, access, export, correction, erasure or anonymization, legal-basis records, exceptions, and retention enforcement | Privacy milestone plan |
| Health checks, metrics, logs, alerts, backups, restore verification, migration rehearsal, promotion, rollback or run-forward, and runbooks | Operational-assurance milestone plan |

## Open decisions

Open decisions stay in the [`STRATEGY.md` decision register](../../STRATEGY.md) until the owning milestone resolves them. They must not be inferred from a local handoff.

| Decision | Resolution authority |
| --- | --- |
| Supported production database and database/credential isolation model | Deployment and persistence plan, backed by compatibility evidence for selected component versions |
| Public control-plane API style and contract | Control-plane API plan and ADR |
| Whether the first administration surface is a UI or operator-facing APIs and tools | Administration milestone plan |
| Boundary between globally shared and application-owned profile attributes | Application-account and profile plan and data-ownership ADR |
| Initial privacy jurisdictions and retention periods | Privacy milestone plan with legal and maintainer confirmation |
| Audit integrity, storage, and export format | Audit milestone plan and threat model |
| Local and production deployment packaging, including whether a first-class Google Cloud reference is adopted | Deployment milestone plan and ADR |
| Aggregate-stack and shared-package release/versioning policy | Release-management plan |
| Minimum supported Elixir, OTP, database, and container-runtime versions | The first implementation plan that introduces each toolchain, supported by compatibility evidence |

## Superseded local assumptions

- The project-source license is no longer open: Apache-2.0 is confirmed by [`LICENSE`](../../LICENSE).
- The repository uses a documented monorepo-oriented ownership layout; implementation directories remain absent until an approved milestone creates them.
- Elixir is the approved control-plane direction, while exact Elixir, Phoenix, and OTP versions remain deferred.
- Hydra remains optional by decision, not merely by assumption.
