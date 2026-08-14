---
id: "0008"
title: "Use Docker Compose for the local development profile"
status: accepted
date: "2026-08-14"
decision-makers:
  - "Repository maintainer"
supersedes: []
superseded_by: null
---

# ADR 0008: Use Docker Compose for the local development profile

## Context and scope

The repository needs a repeatable local and continuous-integration fixture for
real, independently upgradeable Kratos and SpiceDB releases before later
milestones create the control plane or application integrations. The fixture
must express one-shot migration work, health-gated startup, internal networks,
local persistence, and exact image identities without introducing a project
application runtime or selecting a production deployment architecture.

This decision governs only the Milestone 2 local/test component profile and its
evidence runner. It does not select production packaging, a container
orchestrator for deployed realms, a production database topology, a cloud
provider, a public API, or a release model. It also does not define a canonical
identity schema, a canonical SpiceDB schema, or a later client protocol.

## Decision drivers

- Exercise unmodified Kratos and SpiceDB artifacts through one reproducible
  workstation and ephemeral-CI composition.
- Express migration completion, health dependencies, internal-only endpoints,
  a persistent volume, and bounded cleanup without adding an application
  toolchain.
- Keep privileged component interfaces internal while permitting only the
  local/test integration surfaces required by later milestones on an attested
  daemon-host loopback.
- Make the orchestration model inspectable without resolving generated
  credentials into retained diagnostics.
- Preserve independent upstream upgrades and evidence claims for exact image,
  configuration, host, and architecture identities.
- Keep reversal inexpensive because production constraints are deliberately
  unknown.

## Considered options

### Docker Compose local/test profile

Use a repository-owned Compose model behind a guarded operator command. The
model can represent jobs, long-form dependency conditions, health checks,
networks, and volumes in a small profile that works on a developer workstation
and a GitHub-hosted Linux runner. This adds a Compose dependency and requires
strict context, credential, state, and cleanup controls.

### Repository-owned direct process supervisor

A shell or application-level supervisor could start the services directly.
That would avoid Compose, but it would recreate network, volume, dependency,
and resource-ownership behavior in custom code and would make container
identity and cleanup harder to review.

### Kubernetes or Helm development profile

Kubernetes could model jobs, probes, secrets, and persistent storage while
resembling a possible production platform. It would add a cluster dependency
and prematurely bias production packaging without evidence that the first
production shape will use Kubernetes.

### No repository-owned executable profile

Maintainers could run upstream quickstarts or independent commands. This has
the smallest repository footprint, but mutable defaults, demo credentials,
unrecorded ordering, and workstation-specific behavior could not support a
reviewable compatibility claim.

## Decision and rationale

Use Docker Compose for one repository-owned local/test profile. Require the
Docker Compose plugin at version `2.35.0` or newer because the profile depends
on long-form dependency behavior and secret-safe model validation with
`config --no-env-resolution`. A compatibility result applies only to the exact
Docker Engine or Desktop, Compose, host operating system, architecture, image,
configuration, and fixture identities recorded by the evidence; the version
floor is not a general support claim for every newer host tuple.

The first profile evaluates Kratos `v26.2.0`, SpiceDB `v1.56.0`, and
`curlimages/curl` `8.21.0` as readable tags paired with registry-specific OCI
index digests and selected platform-child digests. Version support remains
owned by the [dependency policy](../../policies/dependency-management.md) and
its evidence records, not by this ADR.

Kratos uses SQLite in a per-checkout named volume so restart and baseline
migration behavior are observable. SpiceDB uses memdb and deterministically
rebuilds only noncanonical test fixtures after each process start. A guarded
`bin/local-stack` command owns lifecycle ordering, local Docker-context
attestation, provenance, serialization, diagnostics, and exact-resource reset.
Only the Kratos public HTTP surface and authenticated SpiceDB gRPC test surface
may be bound to the attested daemon host's `127.0.0.1`; Kratos administration,
health, migration, probe, and bootstrap interfaces remain on the internal
Compose network with no host-published port.

This is a local component fixture, not a production deployment. Raw Compose is
inspectable but is not the supported lifecycle interface. GitHub Actions may
run the same profile on a hosted ephemeral pull-request runner to provide
review evidence, but contributor-controlled execution cannot certify its own
support claim.

## Consequences

- Maintainers gain one reviewable local/test topology with explicit component,
  network, state, and readiness boundaries.
- The repository must maintain the Compose feature floor, guarded operator
  interface, exact artifact inventory, architecture-specific evidence, and a
  scoped [threat model](../../security/local-development-environment-threat-model.md).
- Persistent Kratos state must remain paired with its generated cipher material
  and provenance journal. Reset requires serialized, retry-safe, exact-resource
  deletion rather than a broad Compose, volume, or Docker prune operation.
- SpiceDB state is deliberately ephemeral and its fixture schema is test-owned;
  it does not establish application authorization conventions.
- Trusted local Docker-daemon users remain inside the profile's trust boundary
  and may inspect injected values or join internal networks. The profile must
  document and bound this residual risk rather than claiming isolation from the
  daemon administrator.
- The local plaintext and development-mode allowances cannot be promoted to a
  nonlocal environment or production claim.
- Production orchestration and persistence remain open and may differ
  completely from this profile.

## Reversal cost

**Low.** The choice is confined to local/test orchestration and does not define
an application interface or production artifact. Reversal would replace the
Compose model and `bin/local-stack` implementation, reproduce its lifecycle,
security, and compatibility evidence under the successor, update the local
runbook and dependency records, and safely retire profile-scoped state. No
production data or public contract should require migration because neither is
authorized by this decision.

## Confirmation and fitness checks

- The profile contains only the approved local/test Kratos, SpiceDB, migration,
  bootstrap, and probe roles; it contains no application runtime, excluded
  upstream component, or production datastore.
- Every runtime image is an allowlisted readable tag paired with an OCI index
  digest, and every claimed architecture has an observed child digest and
  provenance disposition.
- The supported operator refuses an unsupported Compose version, a remote or
  ambiguous Docker context, ambient Compose graph overrides, unsafe generated
  files, concurrent lifecycle mutation, and mismatched state provenance before
  mutation.
- Inspection shows only the two approved test surfaces bound to daemon-host
  loopback and no privileged endpoint, Docker socket, host namespace, device,
  or writable repository mount exposed to the profile.
- Fresh-start, migration, readiness, functional positive and negative,
  restart, outage, reset/retry, redaction, and cleanup evidence names the exact
  evaluated revision, configuration, artifacts, host tuple, and architecture.
- Compatibility records use the label **local component-fixture compatibility**
  and explicitly disclaim authentication readiness, authorization readiness,
  production security, production persistence, and untested host tuples.

## Revisit triggers

- The local profile requires behavior that Compose cannot express without
  broad privilege or substantial custom orchestration.
- A required Compose behavior changes or fails on a tuple the project intends
  to support.
- The fixture must run against a remote daemon, on a non-loopback network, or
  in a shared persistent environment.
- A later production-packaging decision proposes reusing this profile outside
  local/test scope.
- Persistent Kratos SQLite or ephemeral SpiceDB memdb no longer provides the
  evidence required by the next approved milestone.
- Security review finds that the Docker-daemon, credential, endpoint, CI, or
  reset boundary cannot be acceptably constrained in this profile.

## Related ADRs

- [ADR 0002](0002-kratos-identity-lifecycle.md) selects Kratos as the human
  identity-lifecycle authority.
- [ADR 0003](0003-spicedb-application-authorization.md) selects SpiceDB as the
  application authorization decision service without making this fixture's
  schema canonical.
- [ADR 0006](0006-exclude-oathkeeper-and-keto.md) keeps excluded upstream
  components out of the profile.
- [ADR 0007](0007-upstream-upgrade-independence.md) requires unmodified,
  independently pinned and evidenced upstream artifacts.

