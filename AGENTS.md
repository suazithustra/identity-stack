# Repository guidance

Milestone 1 is documentation-only. The repository has no application runtime,
build system, test harness, formatter, or linter yet. Do not invent commands for
tools that are not present, and do not add implementation scaffolding merely to
make a command available.

## Read the owning documents

- Start with the [README](README.md) and [strategy](STRATEGY.md).
- Use the [architecture index](docs/architecture/README.md) for the ADR process
  and accepted decisions, and the
  [repository layout](docs/architecture/repository-layout.md) for future path
  ownership.
- Follow the [dependency](docs/policies/dependency-management.md),
  [secrets](docs/policies/secrets-handling.md), and
  [testing](docs/policies/testing-strategy.md) policies.
- Use the [threat-modeling process](docs/security/threat-modeling.md) for
  security-sensitive changes and [SECURITY.md](SECURITY.md) for private
  vulnerability reports.
- Use the [current plan](docs/plans/2026-08-14-001-docs-repository-foundation-plan.md)
  for this milestone and the
  [handoff authority map](docs/project/handoff-authority-map.md) for inherited
  decisions and deferrals.

## Working rules

- Treat accepted and rejected ADR bodies as immutable. Change a settled
  decision through a successor ADR and the lifecycle rules in the architecture
  index.
- Keep deferred decisions open until their owning plan or ADR resolves them.
  Do not infer an answer from local continuity material.
- Keep documentation pointer-first: update the owning document and link to it
  instead of copying normative rules into several files. Use repository-relative
  links for repository documents.
- Files under `docs/handoffs/` are local continuity artifacts. They must be
  excluded only through `.git/info/exclude`, never added to `.gitignore`, and
  never staged or committed.
- Never place credentials or live secret values in tracked files. Use inert
  examples and follow the secrets policy. Keep vulnerability details out of
  public issues and other public channels.
- Do not vendor or patch upstream service source. Follow the dependency policy
  before selecting versions or claiming compatibility.

## Current verification

Run checks from the repository root. These documentation and inventory commands
are available now:

```sh
git status --short --branch
git ls-files --cached --others --exclude-standard | sort
git diff --exit-code HEAD -- LICENSE
ignore_match=$(git check-ignore -v --no-index docs/handoffs/identity-stack-handoff.md) && ignore_source=${ignore_match%%:*} && test "$ignore_source" = "$(git rev-parse --git-path info/exclude)" && { rg -n '^docs/handoffs/?$' .gitignore; test $? -eq 1; }
rg -n '[[:blank:]]+$' .gitignore AGENTS.md README.md SECURITY.md STRATEGY.md docs/architecture docs/plans docs/policies docs/project docs/security; test $? -eq 1
```

Inspect every repository-relative Markdown link after changing documentation.
The [current plan's verification contract](docs/plans/2026-08-14-001-docs-repository-foundation-plan.md#verification-contract)
contains the complete Milestone 1 gates. When a later milestone introduces a
real toolchain, add its project commands together with that toolchain and its
evidence policy.

Before describing work as complete, apply the shared
[definition of done](docs/project/definition-of-done.md). This file does not
replace or restate that checklist.
