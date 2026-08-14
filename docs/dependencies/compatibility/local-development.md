# Local development compatibility ledger

## Provisional workstation result — 2026-08-14

| Field | Value |
| --- | --- |
| Result | **Provisional local component-fixture compatibility: pass on the named workstation tuple.** This is not yet a reviewed support entry. |
| Evaluation owner | Component integration maintainer |
| Evidence reviewer | Pending |
| Implementation identity | Uncommitted worktree based on `d1f6b80fc456760bfc6d6b3f71ef76f36e418edc`; an immutable implementation revision is pending. |
| CI identity | `.github/workflows/local-stack.yml` blob `94dcf2da18baf21de1ea18cd505594d25218cbd2`; immutable GitHub run URL pending. |
| Host tuple | macOS/Darwin `25.6.0`, Apple Silicon `arm64`; Docker client/server `28.2.2`; Docker Compose `2.37.1-desktop.1`; local `desktop-linux` Unix-socket context. |
| Profile identities | Configuration `f94d5f2d238647f3090c6f22786885c4e1190dcd`; fixture set `f81b09a1d958030dcd9e7f42d8805fa2ad38aa0e`. |
| Claim scope | The exact pinned local Kratos, SpiceDB, probe, configuration, fixture, host, and architecture tuple only. |

The local run used the candidate artifacts recorded in
[the upstream component inventory](../upstream-components.md): Kratos
`v26.2.0` on the recorded `linux/arm64` child, SpiceDB `v1.56.0` on the
recorded `linux/arm64` child, and the curl probe `8.21.0` on the recorded
`linux/arm64/v8` child. The images remained bound to their tracked OCI index
digests.

### Evaluated content

| Tracked input | Git blob |
| --- | --- |
| `deploy/local/compose.yaml` | `0fd371c68ccc095f425223611771ee2268909808` |
| `config/upstream/kratos/local/kratos.yaml` | `f88c7839e3e4fa372f325b7eddbf77462d7bc02e` |
| `tests/integration/local_stack/smoke.sh` | `275866e7931071a7fbf87a043f7a7f2797d52a60` |
| Kratos identity schema | `019d946a55df4ff702b172dc9f0af8299e281630` |
| Kratos identity request | `4d0fcdd2d91afda05566672209701c93e34d3783` |
| SpiceDB schema source | `42636a728cf5c1b03d05ea4ecfa86f4bbad90558` |
| SpiceDB schema request | `983263178043d80b2ee777927936203880dac3de` |
| SpiceDB relationship request | `de21cceaac6fdb7895e4954be20c327648b2767d` |
| SpiceDB allow request | `b9d25fbb710b87897767f532b7e4beaf864d82c7` |
| SpiceDB deny request | `612bec1692e01b42f972e210d8b07a1cf066b145` |

Any changed blob, profile identity, artifact digest, workflow behavior, host
tuple, or trust boundary invalidates transfer of this result.

### Observed results

- Guarded initialization, file safety, credential format and uniqueness,
  hostile ambient override, remote-context, lifecycle-lock, stale-lock,
  concurrency, and journal provenance tests passed.
- The resolved Compose model used only pinned artifacts, loopback-published
  Kratos public HTTP and SpiceDB gRPC, an internal network, read-only
  containers and fixture mounts, and dropped Linux capabilities.
- Kratos migration, readiness, synthetic `.invalid` identity create/read,
  repeat lookup across restart, and invalid-session rejection passed.
- SpiceDB current-process bootstrap, allow, deny, omitted-key rejection,
  wrong-key rejection, undeclared-relationship removal, process recreation,
  and deterministic reseed passed.
- Kratos and SpiceDB outage checks failed at their intended gates and recovered
  without deleting Kratos state.
- The Kratos admin endpoint was not host-published and an unprivileged
  non-member pinned container could not reach it.
- Generated credential, cookie, token, probe-output, and component-log scans
  passed. Only sanitized pass/fail summaries were retained.
- Wrapper-owned image-acquisition, Kratos-readiness, SpiceDB-health, and
  aggregate-startup deadlines; signal termination; PID-reuse lock recovery;
  partial-readiness status; and resumable partial/finalizing reset tests passed.
- Confirmed reset rotated the SpiceDB key, rejected the old key, and proved the
  prior Kratos fixture identity absent before creating the new fixture.
- The final aggregate status was ready and the final isolated smoke receipt was
  `local component-fixture compatibility: pass`.
- Three cached-image, clean-state lifecycle samples completed in 27, 28, and 27
  seconds. `init` took 0-1 seconds, `up` 10 seconds, functional `smoke` 14-15
  seconds, and confirmed exact reset 2-3 seconds. Every sample started with new
  credentials/state and ended with its containers, network, Kratos volume,
  credential file, and journal verified absent.

Kratos self-service login, registration, recovery, verification, and settings
method/flow behavior was not configured or evaluated. The local file contains
only the neutral `default_browser_return_url` that Kratos v26.2.0 requires for
configuration validity. Auth flows remain outside Milestone 2.

### Pending gates

- The worktree has no immutable implementation revision yet.
- The GitHub-hosted `linux/amd64` workflow has not run, so there is no immutable
  run URL, reviewed runner tuple, cleanup result, or architecture claim.
- Independent evidence and security reviewers have not approved this entry or
  accepted the trusted-local-Docker-administrator residual risk.
- Image-acquisition timing remains bounded by the operator budget rather than a
  performance claim; the local samples used already-cached pinned images.

Until those gates close, this entry is a transparent workstation result, not a
support claim. It provides no authentication-ready, authorization-ready,
production-security, durability, backup/restore, residency, GDPR, or other
regulatory-compliance evidence.
