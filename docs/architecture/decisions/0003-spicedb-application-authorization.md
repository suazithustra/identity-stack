---
id: "0003"
title: "Use SpiceDB for application authorization"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0003: Use SpiceDB for application authorization

## Context and scope

Consuming applications need consistent authorization decisions over their
resources and relationships, including organization relationships within a
realm. Authentication establishes an identity; it does not establish whether
that identity may perform a protected operation. Authorization therefore needs
an explicit owner and a safe failure rule.

This decision assigns authorization checks to SpiceDB and requires application
code to invoke them at the protected operation. It does not select a
relationship schema, client protocol, API style, caching design, or SpiceDB
release.

## Decision drivers

- Keep authorization enforcement adjacent to the application operation and its
  domain context.
- Use one relationship-based authorization authority across consuming
  applications.
- Deny protected operations when authorization cannot be established.
- Avoid relying on user interfaces or an edge proxy as the final enforcement
  point.

## Considered options

### Application code requests decisions from SpiceDB

The application identifies the protected operation and asks SpiceDB about the
relevant subject, resource, and permission. This keeps enforcement close to
domain behavior and centralizes relationship evaluation, but requires careful
integration and explicit dependency-failure handling in every protected path.

### Each application implements local authorization

Applications could store and evaluate permissions independently. This may
reduce a network dependency, but it duplicates policy semantics, fragments
relationship state, and makes consistent review and cross-application behavior
harder.

### Enforce authorization only at an edge proxy

An identity-aware proxy could make coarse route decisions before requests reach
applications. It cannot reliably understand every domain object or state
transition, so edge-only enforcement risks allowing operations whose decisive
context exists only in application code.

### Use Keto as the authorization service

Keto is another external authorization option. Adopting it would add or replace
a component without improving the selected SpiceDB-centered ownership model.
Its exclusion is recorded explicitly in ADR 0006.

## Decision and rationale

Use SpiceDB as the application authorization decision service. Application
code must request and enforce a SpiceDB decision at each protected operation;
authorization is not delegated solely to a user interface, gateway, or routing
layer.

Protected operations fail closed. If SpiceDB is unavailable, times out, returns
an indeterminate result, or cannot provide a valid decision, the application
denies the operation and performs no protected state change. This model keeps
domain context at the enforcement point while providing a shared relationship
authority.

## Consequences

- Applications own correct placement of authorization checks and the mapping
  from domain operations to SpiceDB relationships and permissions.
- SpiceDB availability and latency affect protected operations; operational
  designs must account for that dependency without weakening fail-closed
  behavior.
- Negative, stale-state, timeout, unavailable-dependency, and indeterminate
  response cases require contract and integration evidence.
- A bypass in a user interface or gateway does not bypass application
  authorization.
- Schema design, consistency choices, client protocol, and caching remain open
  and require later evidence before adoption.

## Reversal cost

**High.** Replacing the authorization authority would affect relationship data,
permission semantics, enforcement points, client integration, failure handling,
and tests across consuming applications. Reversal requires semantic equivalence
evidence, a relationship migration plan, negative authorization tests, and a
safe transition that never defaults protected operations to allow.

## Confirmation and fitness checks

- Reviews trace every protected operation to an application-code SpiceDB check
  using the relevant subject, resource, and permission.
- Negative tests show that denied, unavailable, timeout, malformed, and
  indeterminate outcomes perform no protected state change.
- Architecture reviews find no user-interface or edge-only path treated as the
  final authorization authority.
- Contract and real-component integration evidence covers the selected SpiceDB
  artifact and relationship schema when those choices exist.

## Revisit triggers

- SpiceDB cannot express or enforce an approved authorization requirement.
- Measured dependency behavior prevents an approved availability or latency
  objective while preserving fail-closed semantics.
- A review or incident finds a protected operation without an application-code
  authorization check.
- A new enforcement architecture can demonstrate equivalent domain context,
  consistent relationships, and fail-closed evidence.

## Related ADRs

- [ADR 0001](0001-one-deployment-per-realm.md) distinguishes realm isolation
  from in-realm organization authorization.
- [ADR 0002](0002-kratos-identity-lifecycle.md) assigns human identity lifecycle
  rather than authorization to Kratos.
- [ADR 0006](0006-exclude-oathkeeper-and-keto.md) excludes Oathkeeper and Keto
  from the selected architecture.
- [ADR 0007](0007-upstream-upgrade-independence.md) governs SpiceDB deployment
  and upgrades.
