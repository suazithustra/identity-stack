# Testing strategy

Testing is organized around owned boundaries and evidence, not a pyramid of
test counts. This policy defines the required layers and the evidence needed to
support compatibility and security claims. It does not claim that an
executable toolchain, service topology, or project test command exists yet.

## Layers and gates

| Layer | Primary owner | Dependency reality | Gate and evidence |
| --- | --- | --- | --- |
| Unit | Owner of one module | No network dependency; external behavior is isolated. | Deterministic checks of local logic, edge cases, and error handling with results retained by the future project toolchain. |
| Contract | Provider and consumer boundary owners | Exercises the consumer-visible protocol and semantic expectations; may use controlled fixtures in addition to provider verification. | Versioned contract artifact and evidence that both sides honor success, rejection, malformed, and incompatible cases. |
| Integration | Maintainer of the integration | Uses the real, immutably pinned dependency implementation and the evaluated configuration profile. | Evidence for the exact artifact identity, configuration, positive flows, dependency failures, and security-relevant negative behavior. |
| Migration | Owner of the changed state, schema, or component | Starts from representative pre-change state and uses the real migration or upgrade path. | Upgrade, restart, read and integrity results plus tested rollback, or an explicit restore and forward-recovery disposition. |
| End-to-end | Owner of the assembled deployment profile and participating application owners | Uses the assembled stack and real component versions for a small set of critical journeys. | Journey results, profile and tuple identity, observable security outcomes, and recovery evidence for affected critical paths. |

Unit or test-double results cannot establish compatibility with an upstream
release. A support claim requires contract and real-version integration
evidence for the exact tuple and profile, with migration and end-to-end layers
where the change can affect them. Untested combinations remain unknown under
the [dependency policy](dependency-management.md).

## Boundary coverage matrix

Each implemented seam must refine this matrix with links to its actual
contract and evidence. A conceptual row is not a passing result.

| Provider | Consumer | Evidence owner | Contract artifact | Required layers | Positive focus | Negative and failure focus |
| --- | --- | --- | --- | --- | --- | --- |
| Kratos | Control plane and consuming applications that integrate with identity lifecycle | Identity integration maintainer with each consumer owner | Versioned identity and session boundary contract once selected | Contract, real-version integration, migration when identity state changes, and affected end-to-end journeys | Identity mapping and approved lifecycle or session behavior | Rejection, unavailable or timed-out service, malformed or incompatible response, expired or invalid session, partial lifecycle state, and safe recovery |
| SpiceDB | Consuming application code at each protected operation | Authorization model maintainer with the application domain owner | Versioned relationship schema and operation-to-permission contract | Unit for mapping logic, contract, real-version integration, migration for schema or relationship changes, and protected-operation end-to-end evidence | Valid subject-resource-permission decisions and authorized state change | Denied, unavailable, timeout, malformed, indeterminate, version or schema mismatch, stale or partial state; every case fails closed with no protected state change |
| Optional Hydra profile | Control plane and approved relying integrations | Hydra profile maintainer with each consumer owner | Versioned OAuth 2.0 or OpenID Connect boundary contract once a profile requirement is approved | Contract, real-version integration, migration for clients, grants, or keys, profile-specific end-to-end, and recovery | Only approved provider journeys for the enabled deployment | Invalid client or request, rejected grant, unavailable or timed-out service, key or configuration mismatch, partial state, and safe denial or recovery |
| Control-plane module | Another owned module or consuming application | Control-plane module owner with the consuming owner | Versioned module or external boundary contract once its interface exists | Unit, contract, integration for external dependencies, and affected end-to-end journeys | Shared platform behavior within the module's declared responsibility | Invalid input, downstream rejection or timeout, unauthorized or partial operation, and no leakage of another module's responsibility |
| Consuming application | Its users, administrators, and repository integrations | Consuming-application domain owner | Application-owned operation and data contract, linked from repository integration evidence | Application-owned unit and contract tests plus shared integration and critical end-to-end evidence | Product workflow with identity mapping and correctly enforced authorization | Authentication failure, authorization denial, dependency failure, malformed response, partial-state failure, and no protected state change on uncertain authorization |

Consuming applications retain ownership of product workflows, data, profiles,
organization behavior, and placement of authorization checks. Shared test
evidence confirms the integration boundary; it does not transfer product-domain
ownership to this repository.

## Required negative coverage

At every applicable dependency boundary, test:

- unavailable service, timeout, interrupted connection, and retry exhaustion;
- authentication or authorization rejection;
- malformed, incomplete, unexpected, or semantically incompatible response;
- component-version, contract-version, configuration, or schema mismatch;
- partial writes, duplicate delivery, interrupted migration, and recovery from
  representative partial state where the boundary can mutate data; and
- logging and error behavior that does not expose credentials or
  privacy-sensitive data.

For a protected operation, only an explicit valid SpiceDB authorization
decision permits the state change. Denial, timeout, unavailability, malformed
or indeterminate responses, and inability to evaluate the applicable schema
must all produce a denied operation with no protected side effect. A user
interface or gateway check never substitutes for this application-code
evidence.

## Evidence records

Evidence for a layer records the owner, date, project revision, exact component
identities, configuration profile, contract or schema revision, environment,
scenarios, results, and durable output location. Failed and skipped scenarios
remain visible. Test evidence expires when a relevant artifact identity,
configuration, contract, schema, trust boundary, or protected-operation mapping
changes and must then be reproduced for the new tuple.

Fixtures must be representative without containing credentials or unapproved
sensitive data. Follow the [secrets-handling policy](secrets-handling.md) for
inert values, environment separation, redaction, and accidental disclosure.

## Toolchain boundary

The repository currently has no approved runtime, test harness, container
orchestration command, or CI gate. Plans must name test layers and acceptance
evidence, but must not invent commands to imply those controls exist. When a
later milestone introduces a toolchain, it also documents the real local and
automated commands, ownership, evidence retention, and which gates are
blocking. Until then, review uses documentation and repository checks only.
