# Local development profile

This runbook operates the pinned Kratos and SpiceDB component fixture through
`bin/local-stack`. It is local/test tooling only: it is not an application,
production deployment, authentication integration, authorization-enforcement
proof, durability profile, or residency/compliance implementation.

## Prerequisites

- macOS or Linux with a local Unix-socket Docker context controlled by the
  current user;
- Docker Compose `2.35.0` or newer;
- Git, `jq`, OpenSSL, and the POSIX tools checked by `bin/local-stack`; and
- network access for the first pinned image acquisition.

The wrapper rejects remote Docker contexts and behavior-changing ambient
Docker or Compose overrides. Do not set `DOCKER_HOST`, `DOCKER_CONTEXT`,
`DOCKER_DEFAULT_PLATFORM`, `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`, profiles,
or alternate Compose environment-file variables when using it.

## Normal lifecycle

Run commands from the repository root:

```sh
bin/local-stack init
bin/local-stack up
bin/local-stack status
bin/local-stack smoke
```

`init` creates one ignored credential file and one ignored provenance journal
for this checkout. It refuses to replace either file. `up` validates and pulls
the pinned images, migrates Kratos SQLite, starts both components, and seeds the
test-only SpiceDB memdb fixtures before reporting readiness.

`status` reports Kratos, SpiceDB, bootstrap, and aggregate readiness.
`smoke` is disruptive by design: it creates or finds the reserved `.invalid`
Kratos fixture, checks invalid-session rejection and SpiceDB allow/deny/key
behavior, stops each component in turn, and verifies recovery. Do not treat it
as a passive health check.

To stop while preserving local state:

```sh
bin/local-stack down
```

A later `up` reuses the Kratos SQLite volume and generated credentials. SpiceDB
uses memdb, so its data is recreated and seeded whenever the process is
recreated.

## Local endpoints and trust boundary

| Endpoint | Host exposure | Purpose |
| --- | --- | --- |
| Kratos public HTTP | `127.0.0.1:4433` | Later local integration and the invalid-session smoke check |
| SpiceDB gRPC | `127.0.0.1:50051` | Authenticated local component testing |
| Kratos admin/health | Not host-published | Migration, readiness, and internal synthetic fixture operations |
| SpiceDB HTTP/bootstrap/health | Not host-published | Internal readiness and fixture bootstrap |

Traffic is plaintext because the supported boundary is one trusted local
Docker host. Anyone who administers that Docker daemon can inspect containers,
read injected values, or join their networks. A shared or remote daemon,
non-loopback publication, proxy, or real identity data invalidates this
profile; stop using it, reset it, and design a different security boundary.

Kratos self-service login, registration, recovery, verification, and settings
flows are outside this milestone. The profile makes no claim about them.

## Reset

First preview the exact journal-owned deletion set:

```sh
bin/local-stack reset
```

After reviewing the listed containers, network, Kratos volume, credential
file, and journal, confirm irreversible deletion with:

```sh
bin/local-stack reset --yes
```

Reset verifies the complete project inventory and ownership labels before it
deletes anything. It removes Kratos SQLite and its paired secrets together.
There is no recovery from the deleted local fixture.

If reset is interrupted, rerun the same confirmed command. The journal records
the exact remaining resources. After all Docker resources are verified absent,
reset may remove credentials and then the journal; if interruption occurs
between those final deletions, the validated empty journal is sufficient to
finish. Do not recreate or edit either file by hand.

Never substitute `docker system prune`, `docker volume prune`,
`docker compose down --remove-orphans`, a wildcard, or a label-only deletion.

## Failure and recovery

- A failed `up` preserves the exact discovered resources and records a
  `startup-failed` journal phase. Correct the external problem and retry `up`,
  or use the previewed confirmed reset.
- A port collision must be resolved at the other local process. This profile
  intentionally has no ambient port override.
- A component outage makes `status` and `smoke` nonzero. A normal `up` restores
  the declared profile; `smoke` also restores the outages it injects.
- A live or ambiguous lifecycle lock blocks mutation. Do not delete the lock.
  The wrapper replaces it only when its exact owner record proves the process
  is gone.
- A changed tracked configuration can still be removed through `reset`, which
  uses the recorded journal identity. It cannot be started as if it were the
  old profile.

Diagnostics are deliberately bounded. Do not enable shell tracing, print the
credential file, retain raw container inspection, or paste service responses
into public issues.

## Exceptional manual recovery

Use this path only when the journal is missing/corrupt or the checkout moved
and the wrapper refuses normal reset. Automated deletion is intentionally
unavailable.

1. Stop. Preserve the credential file, journal if present, and Docker state.
   Do not rerun `init`, edit the files, prune resources, or delete by label.
2. Confirm the active context with `docker context show` and
   `docker context inspect <exact-context>`. Continue only for the intended
   local Unix-socket daemon.
3. Perform read-only discovery:

   ```sh
   docker container ls --all --no-trunc --filter label=dev.identity-stack.profile=local
   docker network ls --filter label=dev.identity-stack.profile=local
   docker volume ls --filter label=dev.identity-stack.profile=local
   ```

4. Inspect every returned identifier individually with `docker container
   inspect`, `docker network inspect`, or `docker volume inspect`. Record its
   exact name/ID, attachments, and the Compose project plus
   `dev.identity-stack.checkout`, `dev.identity-stack.config`, and
   `dev.identity-stack.generation` labels. Any missing, conflicting, extra, or
   cross-checkout resource stops recovery.
5. Have a second reviewer compare that inventory with the canonical checkout
   path and any surviving journal. Preview the literal resource IDs/names and
   explicitly approve the irreversible Kratos-volume deletion.
6. Only then remove the literal, individually reviewed containers, network,
   and volume with their specific Docker removal commands. Use no variables,
   substitutions, wildcards, broad Compose command, prune, or orphan cleanup.
   Verify the same read-only discovery is empty before unlinking only
   `deploy/local/.local-stack-credentials.env` and
   `deploy/local/.local-stack-state.json` from the verified checkout.

If ownership cannot be proven exactly, leave the resources untouched and seek
maintainer review.

## Evidence

The [upstream inventory](../dependencies/upstream-components.md) owns artifact,
license, provenance, and advisory records. The
[compatibility ledger](../dependencies/compatibility/local-development.md)
owns exact observed results and open evidence gates. A passing local smoke is
not independently reviewed support and cannot be generalized to another host,
architecture, component, configuration, or production profile.
