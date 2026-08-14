# identity-stack

`identity-stack` is reusable, self-hosted infrastructure for identity and
authorization. It combines independently upgradeable upstream services with a
small control plane while leaving product-domain ownership with consuming
applications.

The repository is currently establishing its documentation and architectural
contracts. It does not yet contain a deployable stack.

## Start here

- [Strategy](STRATEGY.md) explains the problem, approach, intended adopters,
  direction, and open decisions.
- [Architecture](docs/architecture/README.md) indexes accepted decisions, and
  the [repository layout](docs/architecture/repository-layout.md) assigns future
  monorepo ownership without creating placeholder services.
- [Dependency management](docs/policies/dependency-management.md),
  [secrets handling](docs/policies/secrets-handling.md), and
  [testing strategy](docs/policies/testing-strategy.md) own their respective
  repository policies.
- [Security reporting](SECURITY.md) and the
  [threat-modeling process](docs/security/threat-modeling.md) explain how to
  report vulnerabilities and review security-sensitive changes.
- The [current plan](docs/plans/2026-08-14-001-docs-repository-foundation-plan.md)
  defines this foundation milestone, while the
  [decision-provenance map](docs/project/handoff-authority-map.md) identifies
  the maintained authority for inherited decisions and deferrals.
- The [definition of done](docs/project/definition-of-done.md) owns shared
  completion expectations. [Repository guidance](AGENTS.md) provides
  agent-specific navigation and approved commands.
- Project-owned source is provided under the [Apache License 2.0](LICENSE); see
  the [project notice](NOTICE) for attribution.
