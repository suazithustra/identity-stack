# Dependency management and compatibility policy

This policy governs project dependencies and the separately deployed upstream
components used by `identity-stack`. It turns compatibility into an evidence
ledger, not a forecast. No component version or stack tuple is supported until
the exact artifacts and configuration have passed the applicable gates.

[ADR 0007](../architecture/decisions/0007-upstream-upgrade-independence.md)
requires unmodified, independently upgradeable upstream services. The
[testing strategy](testing-strategy.md) defines the evidence layers used here.

## Artifact identity and inventory

Every deployable upstream component must have a readable version reference
paired with immutable artifact identity. For a container, record a readable
release tag and its content digest; the tag is for people and the digest is the
deployed identity. A moving branch, floating version range, or mutable tag by
itself is not a production pin. For other artifact types, record the exact
resolved release and the ecosystem's immutable integrity or lock evidence.

The maintained inventory must record, without placeholder values:

| Field | Required content |
| --- | --- |
| Component and role | Upstream or project dependency and why it is present. |
| Source and provenance | Canonical upstream source and artifact origin. |
| Readable version | Exact release or resolved package version. |
| Immutable identity | Digest, integrity value, or reviewed lock record. |
| Configuration profile | The exact profile whose behavior was evaluated. |
| Runtime scope | Environments or deployment profiles in which it is used. |
| Owner | Person or role accountable for updates and advisories. |
| License obligations | Applicable license, notice, attribution, and source-offer duties. |
| Evidence | Links to the compatibility and release records for this identity. |

No inventory is created for a dependency that does not yet exist. Hydra is
recorded only for deployments using the optional provider profile.

## Compatibility evidence ledger

Each evaluated stack tuple gets one ledger entry. A blank field is not a
passing result, and evidence from a different artifact identity or
configuration profile does not transfer automatically.

| Field | Required content |
| --- | --- |
| Tuple | Exact project revision and immutable identities of every component under evaluation. |
| Configuration profile | Realm and optional-component profile, excluding credentials. |
| Evaluation date and owner | When the evidence was produced and who reviewed it. |
| Contract evidence | Passed consumer-visible protocol and semantic expectations at affected seams. |
| Integration evidence | Results against the real pinned implementations and evaluated configuration. |
| Migration evidence | Representative pre-change state through upgrade, restart, read, and recovery checks when state or schema can change. |
| End-to-end evidence | Critical journeys affected by the tuple. |
| Negative evidence | Dependency failure, rejection, incompatibility, and fail-closed results required by policy. |
| Security evidence | Relevant advisory review and scoped security-review disposition. |
| Operational disposition | Promotion, monitoring, rollback, restore, or recovery readiness. |
| Result | Supported for a named scope, blocked, or unknown. |
| Evidence links | Durable outputs sufficient to reproduce or audit the result. |

An untested tuple is **unknown**, not compatible or supported. A failed or
incomplete gate is **blocked** until the missing evidence is produced and
reviewed. Support statements must name their configuration and scope rather
than implying that all combinations work.

## Update record and review flow

An update changes one dependency at a time unless linked changes are required
and justified by evidence. Its record must include:

1. The current and proposed readable versions and immutable identities.
2. Upstream release notes, security advisories, deprecations, breaking changes,
   and provenance changes relevant to the update.
3. Changes to licenses, notices, attribution, or redistribution obligations.
4. The affected contracts, configuration, schemas, data, operational
   procedures, and trust boundaries.
5. Contract and real-version integration evidence for the resulting tuple,
   plus negative and end-to-end evidence where the testing policy requires it.
6. Migration rehearsal when data, protocol, configuration, or schema may
   change, including representative pre-update state, restart and read checks,
   and data-integrity results.
7. A tested rollback path when reversal is supported, or an explicit restore
   and forward-recovery disposition when rollback is unsafe or unsupported.
8. The compatibility-ledger result, reviewer, promotion scope, and outstanding
   risk.

Promotion cannot turn missing evidence into an assumed pass. Where later
deployment tooling supports staged promotion, use progressively broader
environments with observed health and an explicit stop or recovery condition.
No update automation or staged-promotion mechanism exists merely because this
policy describes its future obligations.

## Vulnerabilities and provenance

The inventory owner monitors the applicable upstream advisory and provenance
sources. A suspected vulnerability is assessed against the exact immutable
artifacts and exposure, then routed through the repository's security process.
Urgency does not waive contract, negative, migration, or recovery evidence;
the review may right-size those gates and document residual risk.

Do not conceal local patches inside an artifact. If an approved requirement
cannot be met through supported configuration or an upstream contribution,
stop and seek an architectural decision before forking or vendoring source.

## Licenses, notices, and attribution

The root Apache-2.0 `LICENSE` governs project-owned source and the root
`NOTICE` records the project notice. They do not replace upstream terms. For
every distributed or deployed upstream artifact, identify its governing
license and preserve all required license text, notices, copyright statements,
attribution, source offers, and modification disclosures. Review changes in
these obligations as part of every dependency update and release disposition.

When build or release artifacts exist, generate a standards-based software
bill of materials from the resolved artifact set, retain it with the release
evidence, and reconcile it with the dependency inventory. This milestone
defines the obligation; it does not create an empty SBOM or select an SBOM
format or generator.

## Automation boundary

Automated dependency-update pull requests are a required capability when
dependency-discovery and update tooling is introduced. Each pull request must
remain subject to human review and provide or link to the upstream notes, old
and new immutable identities, affected license obligations, compatibility
evidence, migration impact, and rollback or restore disposition described
above. Automation must not approve its own change or self-declare an untested
tuple supported. Dependency-update tooling remains inactive. The local profile
now has a pull-request compatibility workflow, exact upstream inventory, and a
provisional evidence ledger; those controls do not provide dependency
discovery, SBOM generation, release promotion, or automated approval. Those
remain explicit future gates, and the update provider and schedule remain open.
