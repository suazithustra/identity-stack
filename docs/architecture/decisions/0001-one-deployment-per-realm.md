---
id: "0001"
title: "Use one deployment per realm"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0001: Use one deployment per realm

## Context and scope

An identity deployment needs an explicit isolation boundary. In this project, a
realm is the population and policy boundary served by one deployed stack. An
organization is different: it is an authorization object within a realm and
may group people, resources, and relationships without creating another
deployment boundary.

Building a shared deployment for several realms would make realm identity a
pervasive application concern. Tenant columns, tenant middleware, tenant cache
keys, and tenant-scoped APIs would have to be correct at every boundary. A
single omission could become a cross-realm disclosure or authorization defect.
This decision establishes the isolation model; it does not choose provisioning,
database topology, hosting, or production packaging.

## Decision drivers

- Make the security isolation boundary simple to identify and review.
- Avoid a pervasive tenant discriminator whose omission could cross security
  boundaries.
- Keep organizations available as authorization concepts without confusing
  them with deployment isolation.
- Preserve freedom to choose deployment and data topology when operational
  requirements are known.

## Considered options

### One deployment per realm

Each deployed stack serves one realm. This makes deployment selection, rather
than repeated tenant filtering, the primary realm-isolation mechanism. It
reduces accidental cross-realm paths, but operating many realms may require
more deployment automation and capacity than a shared stack.

### Built-in multi-tenancy in one deployment

One stack could serve several realms by carrying a tenant identifier through
storage, middleware, caches, jobs, and APIs. This can consolidate operations,
but it makes tenant columns, tenant middleware, tenant cache keys, and
tenant-scoped APIs mandatory throughout the system. The resulting blast radius
and review burden are inconsistent with the intended isolation model.

### Treat organizations as deployment tenants

Each organization could become an isolated tenant or deployment. This appears
to reuse a familiar organizational boundary, but organizations are application
authorization objects and can have relationships that do not match operational
isolation. Conflating the two would constrain product-domain modeling and make
organization changes operational events.

## Decision and rationale

Use one deployment per realm and do not build a general built-in tenancy
mechanism. A realm is selected by reaching its deployment; realm identity is
not propagated as a generic tenant dimension inside that deployment.
Organizations remain objects modeled in application authorization within a
realm. This choice minimizes the number of mechanisms that must enforce realm
isolation while preserving organization modeling where it belongs.

## Consequences

- Cross-realm isolation can be assessed at deployment and integration
  boundaries instead of relying on ubiquitous tenant filtering.
- Platform conventions must not introduce tenant columns, tenant middleware,
  tenant cache keys, or tenant-scoped APIs as a hidden multi-realm mechanism.
- Organization membership and permissions remain authorization concerns and
  do not decide where a realm is deployed.
- Supporting many realms creates an operational need for repeatable deployment
  and upgrade procedures.
- Storage, networking, provisioning, and packaging remain open decisions; they
  must preserve the one-realm boundary when selected.

## Reversal cost

**High.** A shared multi-realm deployment would require a realm discriminator
across interfaces, data, caches, background work, authorization context, and
operations. Reversal would need a complete isolation design, migration plan,
negative cross-realm tests, and evidence that every affected boundary fails
safely.

## Confirmation and fitness checks

- Architecture and interface reviews identify one realm for each deployment.
- Schema and interface reviews find no platform-wide tenant column,
  tenant-propagation middleware, tenant cache-key convention, or tenant-scoped
  API convention intended to multiplex realms.
- Authorization models treat organizations as in-realm objects rather than
  deployment selectors.
- Isolation tests introduced with executable interfaces include negative
  cross-realm cases at every external integration boundary.

## Revisit triggers

- A confirmed requirement demands multiple independently governed realms in a
  single deployment.
- Operational evidence shows that one deployment per realm cannot meet an
  approved scale, availability, or cost constraint.
- An upstream component introduces a verified isolation model that changes the
  risk or reversal cost materially.
- A fitness check finds a realm discriminator being propagated as implicit
  built-in tenancy.

## Related ADRs

- [ADR 0003](0003-spicedb-application-authorization.md) assigns in-realm
  authorization decisions, including organization relationships, to SpiceDB.
- [ADR 0007](0007-upstream-upgrade-independence.md) governs how each realm's
  upstream components are deployed and upgraded.
