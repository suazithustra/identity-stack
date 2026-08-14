#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)
WORKFLOW="$ROOT_DIR/.github/workflows/local-stack.yml"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

[ -f "$WORKFLOW" ] || fail 'local-stack pull-request workflow is missing'

grep -Eq '^  pull_request:[[:space:]]*$' "$WORKFLOW" ||
  fail 'workflow is not limited to the pull_request event'
if grep -Eq 'pull_request_target|workflow_run|self-hosted|\$\{\{[[:space:]]*secrets\.|actions/(cache|upload-artifact)@' "$WORKFLOW"; then
  fail 'workflow contains a privileged event, secret, self-hosted runner, cache, or artifact channel'
fi

grep -Eq '^permissions:[[:space:]]*$' "$WORKFLOW" || fail 'workflow lacks explicit permissions'
grep -Eq '^  contents:[[:space:]]+read[[:space:]]*$' "$WORKFLOW" ||
  fail 'workflow does not restrict repository contents to read-only'
if grep -Eq '^  (id-token|packages|actions|checks|deployments|issues|pull-requests|statuses):' "$WORKFLOW"; then
  fail 'workflow grants an unnecessary token scope'
fi

grep -Eq '^    runs-on:[[:space:]]+ubuntu-[0-9]+\.[0-9]+[[:space:]]*$' "$WORKFLOW" ||
  fail 'workflow does not name a GitHub-hosted Ubuntu runner image'
grep -Eq '^    timeout-minutes:[[:space:]]+[0-9]+[[:space:]]*$' "$WORKFLOW" ||
  fail 'workflow has no bounded job timeout'

grep -Eq 'uses:[[:space:]]+actions/checkout@[0-9a-f]{40}([[:space:]]|$)' "$WORKFLOW" ||
  fail 'checkout action is not pinned by a full commit SHA'
grep -Eq 'persist-credentials:[[:space:]]+false' "$WORKFLOW" ||
  fail 'checkout credentials are persisted'

for required_command in \
  'tests/integration/local_stack/workflow_test.sh' \
  'tests/integration/local_stack/init_test.sh' \
  'tests/integration/local_stack/config_test.sh' \
  'tests/integration/local_stack/deadline_signal_test.sh' \
  'tests/integration/local_stack/startup_deadline_test.sh' \
  'tests/integration/local_stack/bootstrap_test.sh' \
  'tests/integration/local_stack/lifecycle_test.sh' \
  'tests/integration/local_stack/startup_failure_test.sh' \
  'tests/integration/local_stack/post_reset_test.sh' \
  'bin/local-stack init' \
  'bin/local-stack up' \
  'bin/local-stack smoke' \
  'bin/local-stack status' \
  'bin/local-stack down' \
  'bin/local-stack reset --yes'; do
  grep -Fq "$required_command" "$WORKFLOW" ||
    fail "workflow omits required gate: $required_command"
done

grep -Eq 'if:[[:space:]]+always\(\)' "$WORKFLOW" ||
  fail 'workflow cleanup is not guaranteed after failure'

printf '%s\n' 'ok - workflow is pull-request-only, least-privilege, pinned, bounded, and cleanup-safe'
