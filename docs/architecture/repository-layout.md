# Target repository layout and ownership

This document assigns one future home and one accountable owner to each major
repository concern. It describes a monorepo-oriented target layout; it is not
an implementation inventory. Paths marked as future remain absent until an
approved milestone introduces substantive content for them. Do not create
empty directories or placeholder files to reserve this shape.

The accepted architecture remains authoritative: one deployment serves one
realm, Kratos owns the human identity lifecycle, SpiceDB owns authorization
decisions enforced by consuming applications, and Hydra is an optional
deployment profile. The project-owned control plane is an Elixir modular
monolith, while upstream services stay unmodified and independently
upgradeable. See the [architecture decision index](README.md).

## Cross-boundary design principles

These constraints apply to future interfaces and workflows that cross a
component or ownership boundary. They define required properties without
selecting the still-open public API shape, identifier format, audit storage or
retention, or implementation mechanisms.

- Keep interfaces narrow and versioned so providers and consumers can change
  against an explicit contract.
- Use stable opaque identifiers for identity and authorization references.
  Mutable traits such as email addresses and display names must not become
  relationship keys or authorization identities.
- Give every workflow that mutates shared authorization relationships an
  explicit accountable owner and contract, including who may request and
  perform the mutation.
- Keep authentication, authorization, and application-domain decisions
  separate. Establishing identity does not grant permission or decide product
  behavior.
- Require explicit authentication and authorization for privileged operations,
  grant least privilege, and deny by default when either decision cannot be
  established.
- Accept propagated identity context only through a boundary that authenticates
  it and protects its integrity. A backend must not trust caller-supplied
  identity headers as identity evidence.
- Store and duplicate only the personal data needed for the owning capability;
  do not copy identity attributes merely for convenience.
- Make privileged actions and security-relevant failures auditable without
  recording credentials or unnecessary personal data.
- Define retry and idempotency behavior for workflows that change external
  state so a retry cannot silently duplicate a completed effect or expand
  privilege.

Apply the [threat-modeling process](../security/threat-modeling.md),
[secrets-handling policy](../policies/secrets-handling.md), and
[testing strategy](../policies/testing-strategy.md) when a later milestone
makes one of these boundaries concrete.

## Ownership map

| Concern | Target path | Accountable owner | Boundary |
| --- | --- | --- | --- |
| Control-plane application | `apps/control_plane/` | Control-plane maintainers | Project-owned shared platform behavior in one modular-monolith deployable; not human credential authority, authorization policy evaluation, or consuming-application product behavior. |
| Shared Elixir packages | `packages/elixir/` | Control-plane maintainers | Reusable Elixir code with demonstrated use across owned modules or applications; not a speculative extension framework. |
| Upstream service configuration | `config/upstream/kratos/`, `config/upstream/spicedb/`, and optional `config/upstream/hydra/` | Component integration maintainers | Supported configuration for separately deployed, unmodified upstream services; no vendored or patched upstream source. |
| SpiceDB relationship schemas | `schemas/spicedb/` | Authorization model maintainers with consuming-application domain owners | Versioned relationships and permissions. Consuming applications still own placement and enforcement of checks for their protected operations. |
| Cross-boundary test suites | `tests/contract/`, `tests/integration/`, `tests/migration/`, and `tests/e2e/` | Maintainers of the boundary under test | Evidence across owned boundaries. Unit tests remain beside their owning code unless a later toolchain establishes another convention. |
| Deployment assets | `deploy/` | Deployment maintainers | Realm-scoped packaging and environment composition once selected; no production packaging or provider is chosen by this layout. |
| Operational runbooks | `docs/runbooks/` | Operators of the documented capability | Recovery, upgrade, rollback or restore, incident, and routine operational procedures backed by the deployed profile. |
| Implementation plans | `docs/plans/` | Author and reviewers of the planned change | Reviewable, time-bounded execution plans and their acceptance traceability. |
| Security process and scoped models | `docs/security/` | Security reviewer and change owner | Threat-modeling process, templates, and scoped models. Secrets-handling rules remain in the policy directory. |
| Repository policies | `docs/policies/` | Repository maintainers and named subject owner | Durable cross-cutting requirements for dependencies, secrets, and testing. |
| Architecture decisions | `docs/architecture/decisions/` | Named decision-makers | Accepted constraints, alternatives, consequences, fitness checks, and explicit supersession history. |

Consuming applications own their product data, workflows, domain rules,
application profiles, organization behavior, and application-code
authorization enforcement. They need not live in this repository. When an
integration with one is introduced here, the owning application team and the
repository boundary maintainer jointly own its contract and evidence; that
does not transfer the application's product domain to the control plane.

## Creation rules

A future path may be created only when an approved plan names its first
substantive artifact, owner, acceptance criteria, and applicable security and
test evidence. Add only the portion needed for that milestone. In particular:

- do not create generic service slots, provider abstractions, or empty package
  trees for hypothetical reuse;
- do not add Oathkeeper, Keto, or compatibility placeholders for them;
- do not introduce Hydra configuration unless an approved deployment has an
  OAuth 2.0 or OpenID Connect provider requirement;
- do not add upstream source trees or repository-local patches; and
- do not infer a database, public API style, runtime version, deployment
  platform, aggregate versioning scheme, or secrets backend from these paths.

Those choices remain open in the [strategy](../../STRATEGY.md) until a later
plan has sufficient constraints and evidence to resolve them.

## Ownership changes

Moving a concern across the boundaries above requires review of the affected
contracts, tests, threat model, operational procedures, and accepted ADRs. A
change that overturns an accepted architectural boundary requires a successor
ADR rather than an undocumented layout edit.
