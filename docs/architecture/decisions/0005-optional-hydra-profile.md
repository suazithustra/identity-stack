---
id: "0005"
title: "Make Hydra an optional deployment profile"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0005: Make Hydra an optional deployment profile

## Context and scope

Some deployments may need the stack to act as an OAuth2 or OpenID Connect
provider for external clients. That capability is not required for the core
human identity and application authorization boundaries. Deploying a provider
without a concrete protocol requirement would add endpoints, keys, client
management, consent behavior, and operational exposure unnecessarily.

This decision governs whether Hydra is part of a deployment. It does not choose
a Hydra release, configure clients or flows, define consent interfaces, choose
packaging, or decide that any current deployment requires the profile.

## Decision drivers

- Keep the baseline stack smaller when OAuth2/OIDC provider behavior is not
  needed.
- Use a purpose-built upstream provider when an approved requirement does need
  that behavior.
- Avoid implementing token-protocol behavior in the control plane.
- Make the additional security and operational surface explicit and testable.

## Considered options

### Optional Hydra profile

Hydra is absent from the baseline and enabled only for a deployment with an
approved OAuth2/OIDC provider requirement. This keeps optional complexity out
of other realms, but requires the profile boundary and its integration evidence
to remain explicit.

### Deploy Hydra in every realm

Every stack could include Hydra for uniformity and future readiness. This
simplifies a component inventory superficially, but exposes and operates a
protocol provider even where no requirement justifies it.

### Exclude OAuth2/OIDC provider capability entirely

The project could declare external protocol-provider use out of scope. This is
simple, but would block a legitimate deployment need already anticipated by the
architecture.

### Implement provider behavior in the control plane

Custom token and protocol behavior could avoid another upstream component, but
would expand security-critical project-owned code and the control-plane scope.

## Decision and rationale

Treat Hydra as an optional deployment profile. Do not deploy or configure it in
the baseline. Enable the profile only when an approved deployment requirement
calls for this stack to provide OAuth2 or OpenID Connect behavior. When enabled,
Hydra remains a separately deployed upstream component and the deployment must
carry profile-specific threat analysis, compatibility evidence, and operational
ownership.

## Consequences

- Realms without an OAuth2/OIDC provider requirement do not carry Hydra's
  endpoints, keys, configuration, or operational burden.
- A Hydra-enabled profile adds explicit security, integration, key-management,
  upgrade, and recovery obligations.
- The control plane may coordinate project-owned integration but does not
  reimplement Hydra's protocol-provider role.
- No current client model, flow, release, UI, storage, or packaging choice is
  implied by accepting this ADR.

## Reversal cost

**Medium.** Enabling the profile requires deployment and integration work but
does not change the baseline architecture. Removing an active profile may be
costlier because clients, grants, keys, and protocol contracts must be migrated
or retired with evidence that no relying party is stranded.

## Confirmation and fitness checks

- Baseline deployment designs and inventories contain no Hydra component or
  exposed Hydra endpoint.
- Every proposed Hydra-enabled deployment cites an approved OAuth2/OIDC
  provider requirement.
- A Hydra-enabled profile has scoped threat analysis, exact artifact inventory,
  contract and integration evidence, key lifecycle ownership, and tested
  recovery behavior before release.
- Reviews find no custom OAuth2/OIDC provider implementation in the control
  plane.

## Revisit triggers

- The baseline product scope acquires an approved, universal OAuth2/OIDC
  provider requirement.
- Hydra cannot satisfy an approved protocol or security requirement.
- Operational evidence shows optional-profile separation is unsafe or
  impractical.
- A review finds Hydra deployed without a documented provider requirement and
  profile-specific evidence.

## Related ADRs

- [ADR 0002](0002-kratos-identity-lifecycle.md) assigns human identity lifecycle
  to Kratos; enabling Hydra does not change that authority.
- [ADR 0004](0004-elixir-control-plane.md) defines the control-plane boundary
  around project-owned integration behavior.
- [ADR 0007](0007-upstream-upgrade-independence.md) governs Hydra artifacts and
  upgrades when the optional profile is enabled.
