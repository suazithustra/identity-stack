# Strategy

## Target problem

Teams that self-host identity infrastructure need authentication and
authorization components to behave as one reviewable system without turning
their applications into infrastructure glue. They also need clear ownership,
security review, and upgrade evidence without maintaining forks of upstream
services or moving product-domain behavior into a shared platform.

## Approach

`identity-stack` provides reusable infrastructure around independently
upgradeable upstream components. Kratos owns the human identity lifecycle,
SpiceDB makes authorization decisions requested by applications, and Hydra can
be included when an OAuth 2.0 or OpenID Connect provider is required. A small
Elixir modular-monolith control plane fills shared platform gaps. Consuming
applications continue to own their product data, workflows, and domain rules.

Each deployment serves one realm; organizations within a realm are
authorization objects rather than infrastructure isolation boundaries. The
[architecture decision records](docs/architecture/README.md) are the authority
for these boundaries and their consequences.

## Intended adopters

- Platform teams that want to operate a coherent identity and authorization
  foundation on infrastructure they control.
- Application teams that need shared identity capabilities while retaining
  ownership of product-specific accounts, profiles, organizations, and
  workflows.
- Maintainers who value upstream upgrade independence and evidence-backed
  compatibility over vendoring or patching external services.

## Success signals

- A new reader can identify component and application ownership without relying
  on unwritten context.
- Applications can use shared identity and authorization capabilities without
  surrendering product-domain ownership.
- Compatibility and upgrade claims are supported by recorded contract,
  integration, migration, and operational evidence.
- Security-sensitive changes trigger scoped threat review, and protected
  operations fail closed when authorization cannot be established.
- Upstream components remain replaceable or upgradeable through explicit,
  reviewable procedures rather than repository-local forks.

## Current investment track

Milestone 2 establishes a pinned Docker Compose local/test fixture for Kratos
and SpiceDB, with generated local credentials, guarded lifecycle operations,
real component smoke checks, and narrowly scoped compatibility evidence. It is
an integration target for later work, not a control plane, consuming
application, production deployment, or regulatory-compliance profile.

The approved [global realm data-residency Product Contract](docs/plans/2026-08-14-1804-feat-global-realm-data-residency-plan.md)
sets the future stack-versus-consumer responsibility boundary. Its production
topology and jurisdiction profiles are not implemented by the local fixture.

## Milestone direction

Later milestones should proceed in narrow, reviewable slices: define control
plane and application-facing contracts, select and pin component versions only
with compatibility evidence, implement integration behavior with failure-mode
coverage, and add operational deployment material alongside the security and
migration evidence it requires. Each slice must preserve the accepted
architecture or replace it through an explicit decision record.

## Non-goals

- Operating a commercial hosted identity service.
- Building a generalized plugin or extension platform.
- Providing built-in tenancy within one deployment.
- Absorbing consuming applications' product data, workflows, or domain policy.
- Vendoring or maintaining repository-local forks of upstream services.
- Presenting the current documentation foundation as a deployable or
  production-ready system.
- Resolving later-milestone choices before their constraints and evidence are
  available.

## Open decisions

The following choices remain intentionally open. A later plan and, where
appropriate, an architecture decision must resolve them before implementation:

- Production database topology and credential isolation.
- Public API contract style.
- Initial administrative interface shape.
- The boundary between shared and application-owned profile attributes.
- Exact production residency-jurisdiction profiles and retention periods.
- Audit integrity, storage, and export design.
- Production deployment packaging and the first GCP reference shape.
- Aggregate and client-package release and versioning policy.
- Minimum supported Elixir, OTP, database, and container-runtime versions.
