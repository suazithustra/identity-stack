# Threat-modeling process

Threat modeling in `identity-stack` is incremental. Each milestone and
security-sensitive change updates the model for the boundaries it introduces
or changes. The repository does not yet define executable interfaces,
production deployment packaging, a database topology, or complete data flows,
so Milestone 1 cannot and does not claim a complete threat model.

This process owns scoped security review. The
[secrets-handling policy](../policies/secrets-handling.md) owns credential
hygiene, the [testing strategy](../policies/testing-strategy.md) owns evidence
layers, and the [dependency policy](../policies/dependency-management.md) owns
artifact identity and compatibility evidence. The
[definition of done](../project/definition-of-done.md) links those authorities
into a shared completion gate.

## Known coarse boundaries

The accepted architecture establishes boundaries that every scoped model must
preserve and refine as interfaces become concrete:

- One deployed stack serves one realm. Deployment selection is the coarse
  realm-isolation boundary; organizations are authorization objects inside a
  realm, not infrastructure tenants.
- Kratos owns human identities, credentials, lifecycle flows, and sessions.
  The control plane and consuming applications are not parallel credential or
  session authorities.
- Consuming application code enforces each protected operation using an
  explicit SpiceDB decision. Denial, timeout, unavailability, malformed or
  indeterminate responses, and inability to evaluate authorization fail closed
  with no protected state change.
- The Elixir control plane owns demonstrated shared platform behavior while
  consuming applications retain their product workflows, domain rules, and
  product data.
- Kratos, SpiceDB, and optional Hydra are separately deployed, unmodified
  upstream components. Each integration crosses an independently versioned
  dependency boundary.
- Hydra adds protocol endpoints, clients, keys, and operational exposure only
  for a deployment with an approved provider requirement.
- Development, test, staging, and production are separate credential and data
  environments. Credential scope must not create a hidden cross-realm
  authority.

These statements are a starting map, not proof about networking, storage,
runtime configuration, public APIs, privacy jurisdiction, retention, or
deployment controls. Those details remain open until an approved change makes
them concrete.

## When a review is required

Create or update a scoped threat model when a plan or change introduces or
alters any of the following:

- authentication, sessions, identity lifecycle, recovery, or verification;
- authorization relationships, permissions, enforcement points, or privileged
  operations;
- an entry point, exposed interface, administrator capability, or trust
  boundary;
- credentials, keys, tokens, certificates, secret storage, or injection;
- privacy-sensitive or otherwise sensitive data, its classification, sources,
  sinks, persistence, schema, migration, logging, deletion, or export;
- an external integration, upstream component, configuration profile, or
  security-relevant dependency;
- realm isolation, environment separation, deployment composition, or network
  exposure; or
- failure, recovery, audit, observability, or incident behavior with security
  consequences.

A dependency update also triggers review when its advisory, provenance,
configuration, protocol, data, migration, or trust-boundary impact changes.

## Review loop and gates

Use the OWASP four-question loop for every scoped model:

1. **What are we working on?** Define the change, owners, actors, assets,
   entry points, data flows, dependencies, trust boundaries, assumptions, and
   explicit exclusions.
2. **What can go wrong?** Identify abuse cases, boundary failures, confused
   ownership, credential exposure, data disclosure or corruption, privilege
   escalation, dependency failure, and unsafe partial-state behavior.
3. **What are we going to do about it?** Give every threat a disposition of
   mitigate, avoid, transfer, or accept. Derive owned requirements and positive
   and negative evidence from that disposition.
4. **Did we do a good enough job?** Check the model against the implemented
   scope, verify requirements and failure behavior, review accepted residual
   risk, and record gaps or new triggers. This judgment is scoped and does not
   assert system-wide completeness.

Apply the loop at these gates:

1. **Planning and design:** Name the model and security owners; establish the
   scope, assets, coarse flows, boundaries, assumptions, access-control
   inventory, data inventory, credential lifecycle, and applicable accepted
   decisions. Unresolved choices stay explicit.
2. **Before implementation of a boundary:** Translate threats into linked
   security requirements, denial behavior, tests, observability needs, and
   recovery expectations. A protected operation must have a defined
   application-code authorization enforcement point and fail-closed cases.
3. **Verification and review:** Attach evidence for the exact interface,
   configuration, and dependency identities; exercise negative paths; confirm
   secrets and sensitive data are not exposed; and record the disposition of
   every identified threat.
4. **Before release or operational use:** Confirm accountable owners,
   credential rotation and revocation, incident and recovery behavior,
   operational evidence, accepted residual risks, and any time-bound
   re-review conditions.
5. **After a trigger, failed assumption, incident, or expiry:** Reopen the
   affected scope before relying on the prior conclusion.

## Required model content

Use the [threat-model template](threat-model-template.md). A scoped model must
contain enough detail to support review and evidence, including:

- scope, owners, status, change summary, explicit exclusions, actors, assets,
  components, data flows, trust boundaries, and applicable accepted decisions;
- each security assumption, current validation evidence, conditions that
  invalidate it, consequence if false, and accountable owner;
- every entry point's authentication requirement, permitted actors and
  operations, authorization decision source and enforcement point, privileged
  behavior, denial behavior, and fail-closed evidence;
- an access-control inventory tracing identities and actors to resources,
  operations, decisions, enforcement, and negative evidence;
- sensitive-data classification, owner, source, sink, transit and at-rest
  protections, logging and redaction, and the current retention and deletion
  disposition;
- credential purpose, service identity, environments, least-privilege scope,
  storage and injection, authorized readers, rotation, revocation, retirement,
  redaction, and validation evidence;
- identified threats and a mitigate, avoid, transfer, or accept disposition;
  and
- derived requirements and evidence traced into the implementing plan,
  acceptance criteria, tests, operational material, and completion record.

Do not invent privacy jurisdictions or retention periods to fill the model.
Record their status as an open decision, describe what information is needed,
and prevent use that depends on an unapproved answer.

## Assumptions and invalidation

An assumption is not evidence. Record the current reason it is believed, the
artifact or review that validates it, and an observable condition that makes
it invalid. Examples of invalidation conditions include a new entry point, a
changed enforcement point, a dependency identity change, a broader credential
scope, a new data sink, an altered deployment profile, or evidence that a
negative path does not fail safely.

When an assumption is unvalidated or invalidated, mark the affected conclusion
as open or blocked, identify the owner and next evidence needed, and re-run the
relevant review gate. Do not preserve a passing security conclusion by merely
editing the assumption's wording.

## Threat disposition and residual risk

Every identified threat has exactly one current disposition:

- **Mitigate:** reduce likelihood or impact through an owned control with
  verification evidence.
- **Avoid:** remove the exposed behavior, data, privilege, or dependency.
- **Transfer:** assign treatment through a defined external responsibility
  while retaining an owner for verifying the transfer's scope and evidence.
- **Accept:** retain a bounded residual risk through an explicit, reviewable
  decision.

An accepted residual risk records the accountable owner, rationale, remaining
impact and exposed scope, validation evidence, compensating controls, and an
observable re-review trigger or expiry. Missing evidence, ownership, or a
re-review condition is not risk acceptance; it is an unresolved security item.

## Traceability and completion

Give model items stable local identifiers. Trace each threat to its
disposition, derived requirements, evidence, residual risk when applicable,
and the plan or change that owns the work. Negative evidence must demonstrate
the actual denial or recovery outcome; for a protected operation, it must show
that uncertain authorization causes no protected state change.

A scoped model can be reviewed only for the boundaries it names. New or
changed boundaries, invalidated assumptions, missing required evidence, and
expired risk acceptance reopen the review. Apply the shared
[definition of done](../project/definition-of-done.md) before describing the
change as complete.
