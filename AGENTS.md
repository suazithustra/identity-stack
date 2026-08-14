# Repository guidance

The repository has a pinned Docker Compose local/test fixture and shell-based
contract tests. It still has no control-plane or consuming-application runtime,
Elixir build, or production deployment toolchain. Do not invent commands for
tools that are not present or generalize the local fixture into those missing
capabilities.

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
- Use the [current plan](docs/plans/2026-08-14-0647-feat-pinned-local-development-environment-plan.md)
  for the local fixture milestone, the
  [local development runbook](docs/runbooks/local-development.md) for operator
  behavior, and the
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

Run checks from the repository root. The supported local operator interface is:

```sh
bin/local-stack init
bin/local-stack up
bin/local-stack status
bin/local-stack smoke
bin/local-stack down
bin/local-stack reset
```

`smoke` deliberately injects component outages; `reset --yes` irreversibly
deletes the exact journal-owned local profile and paired credentials. Read the
runbook before using either. Do not replace the wrapper with raw Compose or
broad Docker cleanup commands.

The current shell and repository checks are:

```sh
git status --short --branch
git ls-files --cached --others --exclude-standard | sort
git diff --exit-code HEAD -- LICENSE
ignore_match=$(git check-ignore -v --no-index docs/handoffs/identity-stack-handoff.md) && ignore_source=${ignore_match%%:*} && test "$ignore_source" = "$(git rev-parse --git-path info/exclude)" && { rg -n '^docs/handoffs/?$' .gitignore; test $? -eq 1; }
shellcheck bin/local-stack tests/integration/local_stack/*.sh
tests/integration/local_stack/workflow_test.sh
tests/integration/local_stack/init_test.sh
tests/integration/local_stack/config_test.sh
tests/integration/local_stack/deadline_signal_test.sh
tests/integration/local_stack/startup_deadline_test.sh
tests/integration/local_stack/bootstrap_test.sh
tests/integration/local_stack/lifecycle_test.sh
tests/integration/local_stack/startup_failure_test.sh
rg -n -g '!docs/handoffs/**' '[[:blank:]]+$' .github .gitignore AGENTS.md README.md SECURITY.md STRATEGY.md bin config deploy docs tests; test $? -eq 1
```

Inspect every repository-relative Markdown link after changing documentation.
The [current plan's verification contract](docs/plans/2026-08-14-0647-feat-pinned-local-development-environment-plan.md#verification-contract)
contains the complete local-profile gates. A local passing result has only the
scope recorded in the
[compatibility ledger](docs/dependencies/compatibility/local-development.md).

Before describing work as complete, apply the shared
[definition of done](docs/project/definition-of-done.md). This file does not
replace or restate that checklist.
