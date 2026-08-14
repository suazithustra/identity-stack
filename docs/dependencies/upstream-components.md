# Upstream component inventory

This inventory records the first candidate local component-fixture tuple. A readable version and resolved artifact identity do not establish support. The [compatibility ledger](compatibility/local-development.md) currently records only a provisional workstation result; support begins only after it binds reviewed evidence to the same immutable implementation, configuration, artifact, host, and architecture identities.

## Candidate tuple resolved 2026-08-14

| Component | Source and publisher | Readable version and OCI index | Platform child identities | License and notice | Provenance and advisory disposition | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| Ory Kratos | `docker.io/oryd/kratos`; [Ory repository](https://github.com/ory/kratos) | `v26.2.0@sha256:2a13bb8d362c7a7ae33bd7c0f5168aee46921f15c916a06346db91c06dc76643` | `linux/amd64@sha256:92eedc292ff8e1a918ac442c88ed0abe44610c75121700963114549908a45ac3`; `linux/arm64@sha256:eaf37b0c1b7b5308ad7a3247706eee032588c9ef8a13fc59dd6422eaa4e079d6` | Apache-2.0; preserve upstream license and notice obligations. | OCI labels bind source revision `9d7085948039ffb8960160d4979f71527b5cf4d5`; no signature, publisher attestation, or SBOM was established by manifest inspection. [GHSA-hgx2-28f8-6g2r](https://github.com/ory/kratos/security/advisories/GHSA-hgx2-28f8-6g2r) and published release/advisory sources were rechecked 2026-08-14; the pin includes the reviewed fix and no broader provenance claim is made. | Component integration maintainer |
| Authzed SpiceDB | `docker.io/authzed/spicedb`; [Authzed repository](https://github.com/authzed/spicedb) | `v1.56.0@sha256:c8a558a6cc1f9379fcdcab0171b623d65e7e5f95c998ebb7f937ca00a7c1598c` | `linux/amd64@sha256:d1ab7720f6866acd667fabd5cf74ab19d7eb240209ad2f5f0f590afcf7fca85b`; `linux/arm64@sha256:66d20e276008ea32605a0318c51cae06ffffa51ac8141b50417d8db5be0a820e` | Apache-2.0; preserve upstream license and notice obligations. | OCI index includes attestation manifests for both selected platform children, but their signatures and contents were not independently verified. [Published advisories](https://github.com/authzed/spicedb/security/advisories) and the changelog were rechecked 2026-08-14; `v1.56.0` is newer than the reviewed fixed releases, including the IPv4-mapped-IPv6 caveat and CVE-2026-40091 fixes. | Component integration maintainer |
| curl container probe | `docker.io/curlimages/curl`; [curl container repository](https://github.com/curl/curl-container) | `8.21.0@sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13` | `linux/amd64@sha256:1ab04d023ece37e6ec991bf3306ad04e0ef0084e94a5c6b6563cfcb9563169db`; `linux/arm64/v8@sha256:56bc0130aabaada5c04bb18d8d7f75e7a78fbcaa38ad44e1811c8c7720606d84` | curl license; preserve image and bundled dependency attribution required by the publisher. | No publisher signature, attestation, or SBOM was established by manifest inspection; this remains an explicit evidence limitation. The exact probe tools were runtime-inventoried, and the image is one-shot, read-only, capability-dropped, internally networked, and receives only the local SpiceDB key. curl security/release sources were rechecked 2026-08-14. | Component integration maintainer |

## CI action resolved 2026-08-14

| Dependency | Source | Immutable identity | Runtime scope | License and provenance | Owner |
| --- | --- | --- | --- | --- | --- |
| GitHub checkout action | [actions/checkout](https://github.com/actions/checkout) | `v7.0.1@3d3c42e5aac5ba805825da76410c181273ba90b1` | GitHub-hosted `ubuntu-24.04`; source checkout only; credentials explicitly not persisted | MIT; the upstream release commit is GitHub-verified. The workflow grants only `contents: read`, uses no repository secrets, and pins this full commit rather than a mutable tag. | Repository automation maintainer |

## Claim and update rules

- The index digest is the tracked runtime reference. Platform-child digests record what each claimed host resolves and must match observed runtime inspection.
- `linux/amd64` and `linux/arm64` remain candidates, not supported platforms, until separate reviewed runs exist.
- Any digest, publisher, configuration, fixture, advisory, license, privilege, network, or host change invalidates compatibility transfer and requires new evidence.
- The probe can establish only the narrow component behavior named in the Milestone 2 plan. It is not a general application client and does not establish a future API choice.
- The local SQLite and memdb stores are test fixtures. This tuple makes no production database, durability, residency, GDPR, authentication-readiness, or authorization-readiness claim.
