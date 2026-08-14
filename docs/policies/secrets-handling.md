# Secrets-handling policy

This policy is the repository authority for credential hygiene. Scoped threat
models apply it to concrete interfaces and deployments; they do not weaken it.
The mechanism used to store or inject production credentials remains an open
decision until a later milestone can evaluate its security and operational
constraints.

## Tracked content

Credentials and secret material must never appear in tracked files. This
includes passwords, tokens, session material, private keys, signing keys,
client secrets, recovery material, database credentials, cloud credentials,
and any value that grants or derives access.

Examples and templates must be inert:

- use unmistakable non-secret labels such as `replace-locally` rather than a
  real value or a value copied from an environment;
- do not publish syntactically valid private keys, bearer tokens, connection
  strings with credentials, or live endpoints containing secret parameters;
- use public test fixtures only when they cannot authenticate to any system and
  their inert purpose is stated; and
- review generated logs, recordings, screenshots, fixtures, and test output as
  tracked content before adding them.

Do not treat encryption, encoding, redaction after review, or an ignored file
as permission to place a real credential in version history.

## Local files and injection

If a later toolchain needs a local secret file, select its exact path
deliberately and add the narrow path or pattern to Git exclusion before any
secret is written. Keep the file outside version control and use only the
approved runtime injection boundary. A contributor must verify both ignore
behavior and staged contents; ignore rules are a guardrail, not secret
management.

Repository examples may document required variable or field names, ownership,
and source, but contain only inert values. Do not add a generic secret file,
secret backend, environment loader, or injection command before an approved
implementation selects one.

## Environment and privilege boundaries

- Keep development, test, staging, and production credentials separate. Never
  reuse a production credential in a lower-trust environment or fixture.
- Issue a credential to one service identity and purpose with the minimum
  permissions and scope required. Shared human or cross-service credentials
  require explicit security review.
- Limit access to the people and workloads that operate the owning boundary.
  Authentication to a secret store does not itself justify access to every
  secret in it.
- Separate realm credentials according to the one-deployment-per-realm
  boundary. Do not introduce a credential that silently becomes a universal
  cross-realm authority.
- Optional Hydra deployments own separate keys and client credentials; those
  secrets do not become baseline-stack credentials.

## Credential lifecycle and ownership

Every credential introduced by a later milestone must have one accountable
owner and a recorded lifecycle:

| Stage | Required disposition |
| --- | --- |
| Creation | Issuer, intended service identity, purpose, environments, least-privilege scope, and approval are known. |
| Storage and injection | Approved storage boundary, authorized readers, delivery path, and non-disclosure checks are documented. |
| Use | Authentication and authorization scope are monitored without logging the credential. |
| Rotation | Owner, rotation trigger or interval, overlap behavior, dependent consumers, validation, and failure recovery are defined. |
| Revocation | An owner can promptly disable the credential and verify that access no longer succeeds. |
| Retirement | The credential is revoked, removed from stores and consumers, and its residual copies are handled according to the scoped security review. |

Credential rotation and revocation must be testable before a production
boundary depends on them. Where an upstream service owns credential semantics,
the repository owner still owns safe configuration, access, rotation,
revocation, and evidence for this deployment.

## Logging and diagnostic material

Logs, errors, traces, metrics labels, audit events, support bundles, test
failures, and command output must not expose credentials. Redact at the
production source rather than relying only on later display filtering. Avoid
logging complete authorization headers, cookies, connection strings, request
bodies, environment dumps, or upstream responses that may contain secret
material. A scoped threat model records sensitive sources and sinks and tests
the selected redaction behavior.

## Accidental disclosure response

Treat a credential exposed in a tracked file, review, log, artifact, message,
or other unauthorized location as compromised; deleting the visible copy is
not sufficient.

1. Stop further distribution and restrict access to the disclosure without
   copying the secret into an issue or another report.
2. Notify the credential owner and security owner through the private security
   process.
3. Revoke the exposed credential, rotate any related material, and validate
   that the old value no longer grants access.
4. Determine the affected environments, systems, realms, identities, logs,
   artifacts, caches, and time window; review for unauthorized use.
5. Remove or redact accessible copies. If version history or published
   artifacts contain the value, coordinate history or artifact remediation
   after revocation rather than assuming deletion erases exposure.
6. Restore dependent services using newly issued least-privilege credentials
   and validate their security and operational behavior.
7. Record the cause, scope, response evidence, residual risk, and preventive
   control in the private incident record. Update the applicable threat model,
   examples, and tests.

External vulnerability details follow the root `SECURITY.md` reporting path;
they must not be placed in a public issue or a personal email.
