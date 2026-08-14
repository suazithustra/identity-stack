---
id: "0006"
title: "Exclude Oathkeeper and Keto"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0006: Exclude Oathkeeper and Keto

## Context and scope

The selected boundaries already place human identity lifecycle in Kratos,
authorization decisions in SpiceDB, enforcement in consuming application code,
and shared project-owned behavior in the control plane. Adding Oathkeeper as an
identity-aware proxy or Keto as another authorization service would overlap
those responsibilities and expand the integration and upgrade surface.

Leaving generalized adapters or empty component slots for excluded services
would still impose their abstractions on the design. This decision excludes
Oathkeeper and Keto and rejects a speculative extension framework. It does not
choose future network ingress, load balancing, or a general reverse-proxy
product.

## Decision drivers

- Keep one clear owner for each identity and authorization responsibility.
- Avoid overlapping enforcement paths and authorization authorities.
- Minimize deployed components and independent compatibility obligations.
- Prevent speculative pluggability from obscuring the selected architecture.

## Considered options

### Exclude Oathkeeper and Keto

The repository carries no deployment, integration, or placeholder architecture
for these components. This keeps boundaries direct and reviewable, but a future
requirement that genuinely needs either component would require a new ADR.

### Add Oathkeeper as the authorization edge

Oathkeeper could enforce route-level access before application code. It can be
useful for coarse edge policy, but it cannot replace authorization at a domain
operation and would create a second enforcement path alongside the selected
application-to-SpiceDB model.

### Add Keto as another or replaceable authorization service

Keto could provide authorization behavior or sit behind a provider interface.
This would duplicate or weaken the selected SpiceDB authority and require
additional semantic, operational, and upgrade compatibility work.

### Build a generalized identity and authorization extension framework

Abstract provider interfaces and empty component slots could make future swaps
look easier. Without two proven implementations or concrete requirements, they
would encode speculative commonality, create unused paths, and make the active
security boundary harder to audit.

## Decision and rationale

Exclude Oathkeeper and Keto from the architecture. Do not add runtime
configuration, dependencies, clients, schemas, placeholder directories, or
deployment profiles for them. Do not build a generalized extension framework
to preserve hypothetical support for either component.

Use the already selected direct boundaries: applications enforce protected
operations using SpiceDB decisions, Kratos owns human identity lifecycle, and
the control plane fills only demonstrated shared platform gaps.

## Consequences

- The deployed component set and compatibility surface are smaller.
- Authorization enforcement remains visible in application code rather than
  split with an identity-aware edge.
- SpiceDB remains the sole selected application authorization service.
- Later adoption of an excluded component requires evidence and a successor
  ADR rather than activation of a dormant abstraction.
- Ordinary infrastructure needs such as ingress are not prohibited, but no
  future choice may silently reintroduce the excluded identity or authorization
  roles.

## Reversal cost

**Medium.** Introducing either component would require redefining responsibility
boundaries, adding deployment and compatibility obligations, and proving that
enforcement remains complete and fail closed. A generalized provider framework
would additionally require at least two concrete implementations and evidence
that their shared contract is stable.

## Confirmation and fitness checks

- Dependency, deployment, and repository inventories contain no Oathkeeper or
  Keto artifact, configuration, client, schema, or placeholder directory.
- Architecture reviews find no generic provider interface whose only purpose is
  hypothetical support for alternative identity or authorization components.
- Protected-operation reviews continue to show application-code enforcement
  using SpiceDB decisions.
- Any proposal to add an excluded component includes a successor ADR with
  concrete requirements, threat-boundary analysis, and compatibility evidence.

## Revisit triggers

- A concrete approved requirement cannot be met by the selected Kratos,
  SpiceDB, application-enforcement, and control-plane boundaries.
- Two independently required implementations demonstrate a stable common seam
  that justifies an extension interface.
- A security review shows that a new edge enforcement layer is necessary and
  can coexist with application authorization without ambiguous ownership.
- The selected SpiceDB approach fails its authorization fitness checks and a
  replacement is evaluated with migration evidence.

## Related ADRs

- [ADR 0002](0002-kratos-identity-lifecycle.md) defines Kratos identity
  lifecycle ownership.
- [ADR 0003](0003-spicedb-application-authorization.md) defines direct
  application-to-SpiceDB authorization and fail-closed behavior.
- [ADR 0004](0004-elixir-control-plane.md) rejects speculative distributed and
  extension boundaries for shared project-owned behavior.
