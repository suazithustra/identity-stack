---
id: "0004"
title: "Use an Elixir modular-monolith control plane"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0004: Use an Elixir modular-monolith control plane

## Context and scope

Kratos and SpiceDB provide focused upstream capabilities, but the complete
stack will need project-owned coordination and integration behavior that does
not belong inside either upstream service. At the same time, consuming
applications have their own product domains and must not be reduced to thin
clients of an expanding central platform.

This decision establishes an Elixir control-plane boundary and its initial
modularity model. It does not select a web framework, public API style,
database topology, runtime version, deployment packaging, or the detailed set
of control-plane modules.

## Decision drivers

- Provide one project-owned home for genuinely shared platform gaps.
- Keep upstream components unmodified and focused on their selected roles.
- Preserve product-domain ownership in consuming applications.
- Avoid premature distributed-service boundaries and their operational cost.
- Make future module extraction depend on evidence rather than speculation.

## Considered options

### Elixir modular-monolith control plane

One deployable control plane contains explicitly bounded modules for shared
platform responsibilities. This supports cohesive development and simpler
operations while retaining internal ownership boundaries, but a weak module
discipline could allow the control plane to accumulate unrelated product
behavior.

### Independent control-plane microservices from the start

Each anticipated capability could begin as a separately deployed service. This
offers deployment isolation, but chooses network and operational boundaries
before load, ownership, and change patterns demonstrate that they are useful.

### Put shared behavior in each consuming application

Applications could implement all integrations independently. This preserves
local autonomy, but duplicates cross-cutting behavior and makes the upstream
component contracts inconsistent.

### Extend or fork upstream components

Project-specific behavior could be added directly to Kratos, SpiceDB, or other
upstream source. This can appear locally convenient, but couples product logic
to upstream internals and conflicts with independent upgrades.

## Decision and rationale

Build project-owned shared platform behavior as an Elixir modular-monolith
control plane. Give each module a clear responsibility and keep the control
plane as one deployable boundary until observed scaling, reliability, or
ownership needs justify extraction.

The control plane fills only genuinely shared platform gaps. Consuming
applications continue to own their product domains, product workflows, and
domain data. A capability does not move into the control plane merely because
more than one application might someday use it.

## Consequences

- Shared integration behavior has a project-owned home without modifying
  upstream components.
- Consuming applications remain responsible for product-specific workflows and
  data, including their application profiles and organization behavior.
- Module boundaries and ownership must be reviewable even though the control
  plane is one deployable unit.
- Premature service-to-service protocols, independent deployments, and generic
  extension points are avoided.
- Exact modules, interfaces, persistence, framework, runtime release, and
  production packaging remain later decisions.

## Reversal cost

**Medium.** Extracting modules into services or moving responsibilities back to
applications would require interface definitions, data and ownership analysis,
deployment changes, and contract evidence. The cost rises if modules share
state or bypass their declared boundaries, so preserving modularity is part of
keeping reversal feasible.

## Confirmation and fitness checks

- Repository-layout and design reviews assign shared platform code to explicit
  control-plane modules and product behavior to consuming applications.
- Dependency reviews find no project-owned patches embedded in upstream
  components.
- Proposed module extraction includes observed scaling, reliability, or
  ownership evidence rather than a speculative future need.
- Boundary tests are added when interfaces exist and demonstrate that modules
  do not reach across ownership boundaries implicitly.

## Revisit triggers

- Measured scaling or availability requirements require independent deployment
  of a control-plane module.
- Stable team ownership or release cadence makes one module operationally
  independent.
- Product-domain behavior is found accumulating in the control plane.
- Elixir can no longer satisfy an approved control-plane requirement.
- Module coupling makes boundary testing or safe independent change
  impractical.

## Related ADRs

- [ADR 0002](0002-kratos-identity-lifecycle.md) keeps human identity lifecycle
  in Kratos rather than the control plane.
- [ADR 0003](0003-spicedb-application-authorization.md) keeps authorization
  decisions in SpiceDB and enforcement in consuming application code.
- [ADR 0005](0005-optional-hydra-profile.md) makes the OAuth2/OIDC provider an
  optional deployment profile rather than a permanent control-plane feature.
- [ADR 0007](0007-upstream-upgrade-independence.md) prevents the control plane
  from absorbing patched upstream source.
