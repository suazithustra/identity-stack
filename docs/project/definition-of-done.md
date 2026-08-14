# Definition of done

This is the repository-wide completion contract. Apply each gate at the level
appropriate to the change, retain links to the resulting evidence, and mark a
gate not applicable only with a reviewable reason. Owning policies and
processes define the detailed rules; this checklist links to them instead of
duplicating them.

## Scope and acceptance

- The change has an approved, bounded objective, acceptance criteria, owner,
  and explicit exclusions.
- Acceptance scenarios cover the intended outcome, meaningful boundaries, and
  relevant failure behavior. Evidence links show the observed result.
- Open decisions remain visible. The change does not silently select a public
  API style, database topology, privacy jurisdiction, retention period,
  deployment mechanism, runtime version, or another deferred choice.
- The final file and behavior scope matches the approved plan; abandoned
  experiments, placeholder structures, and hidden follow-up work are removed.

## Architecture and ownership

- The change preserves the
  [accepted architecture decisions](../architecture/README.md) and the
  [repository ownership map](../architecture/repository-layout.md), or includes
  the required successor decision and ownership updates.
- A new or materially changed boundary, irreversible choice, or accepted
  tradeoff is recorded through the repository ADR process. Existing accepted
  decision bodies are not silently rewritten.
- Product-domain behavior remains with its consuming application, upstream
  components remain unmodified, and new repository paths have substantive
  content and an accountable owner.

## Testing and implementation quality

- The applicable unit, contract, integration, migration, and end-to-end layers
  from the [testing strategy](../policies/testing-strategy.md) are identified.
- Positive, negative, edge, dependency-failure, and partial-state scenarios are
  covered where relevant. Protected operations have fail-closed evidence with
  no protected state change when authorization cannot be established.
- Evidence names the exact revision, component identities, configuration, and
  environment under review. Test doubles alone do not support real-component
  compatibility claims.
- Real formatting, static-analysis, build, and test commands run when an
  approved toolchain provides them. Before then, documentation and repository
  checks are used without inventing commands or claiming unavailable gates.

## Security, privacy, and secrets

- A change that meets a trigger in the
  [threat-modeling process](../security/threat-modeling.md) creates or updates a
  scoped model before its affected boundary is treated as complete.
- Security assumptions have validation evidence and invalidation conditions;
  entry points, access controls, credentials, and sensitive data have owners
  and the required lifecycle and failure records.
- Every identified threat has a disposition. Accepted residual risks include
  an accountable owner, rationale, remaining impact, validation evidence,
  compensating controls, and a re-review trigger or expiry.
- The [secrets-handling policy](../policies/secrets-handling.md) is satisfied:
  tracked content and evidence contain no credentials, examples are inert, and
  rotation, revocation, environment separation, least privilege, and redaction
  are verified where credentials exist.
- Privacy-sensitive data changes record classification, sources, sinks,
  protections, logging, deletion, and the current retention status. Privacy
  jurisdiction and retention choices remain open until explicitly approved.
- External vulnerability-reporting behavior remains consistent with the root
  [security policy](../../SECURITY.md).

## Dependencies, compatibility, and migration

- The [dependency policy](../policies/dependency-management.md) is satisfied for
  every added or changed dependency: immutable identity, provenance, advisory
  review, and applicable license, notice, attribution, and source obligations
  are recorded.
- Compatibility statements are limited to exact tuples and profiles backed by
  contract and real-version integration evidence. Untested combinations remain
  unknown.
- Changes to component, configuration, contract, schema, or data include the
  applicable migration rehearsal and integrity evidence, plus a tested
  rollback path or an explicit restore and forward-recovery disposition.
- Automation-dependent inventory, update, SBOM, or promotion controls are
  claimed only after the corresponding tooling and retained evidence exist.

## Documentation and operations

- User, operator, policy, architecture, and repository-navigation documents
  are updated at their owning locations and link to one another without
  duplicating normative rules.
- Operational effects are reviewed: ownership, observability, failure and
  recovery behavior, incident handling, deployment-profile impact, rollout,
  stop conditions, rollback or restore, and runbook changes are documented
  where applicable.
- A documentation-only change states which runtime and operational gates are
  unavailable or not applicable; it does not imply a deployable or
  production-ready system.
- Applicable project and upstream license, notice, attribution, modification,
  and source-offer obligations are preserved in distributed material.

## Review, simplification, and durable learning

- The final change is reviewed against its acceptance criteria, applicable
  policies, security conclusions, architecture, and ownership boundaries.
  Actionable findings are resolved or retained with an owner and explicit
  disposition.
- The implementation and documentation are simplified after behavior settles:
  duplicate rules, speculative abstractions, stale paths, dead code, and
  unnecessary files are removed while deliberate boundaries remain visible.
- Verification is rerun after review changes, and the completion record retains
  actual results, failures, skipped checks, and reasons rather than an
  unsupported summary.
- Reusable learning is captured in its owning ADR, policy, repository guidance,
  or this contract. A substantive lesson that fits none of those authorities
  may be recorded under `docs/solutions/`; no empty lesson scaffold is created.

The change is done only when all applicable gates above have observed evidence
and no unresolved item invalidates its acceptance, security, compatibility,
migration, documentation, or operational claims.
