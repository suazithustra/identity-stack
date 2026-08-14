#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-startup-failure-test.XXXXXX")
repo_dir="$test_root/repo"
fake_bin="$test_root/bin"
trap 'rm -rf -- "$test_root"' EXIT HUP INT TERM

mkdir -p "$repo_dir/bin" "$repo_dir/deploy/local" "$repo_dir/config/upstream/kratos/local" \
  "$repo_dir/tests/integration/local_stack/fixtures" "$fake_bin"
cp "$ROOT_DIR/bin/local-stack" "$repo_dir/bin/local-stack"
cp "$ROOT_DIR/deploy/local/.env.example" "$repo_dir/deploy/local/.env.example"
cp "$ROOT_DIR/deploy/local/compose.yaml" "$repo_dir/deploy/local/compose.yaml"
cp -R "$ROOT_DIR/config/upstream/kratos/local/." "$repo_dir/config/upstream/kratos/local/"
cp -R "$ROOT_DIR/tests/integration/local_stack/fixtures/." "$repo_dir/tests/integration/local_stack/fixtures/"
cp "$ROOT_DIR/tests/integration/local_stack/smoke.sh" "$repo_dir/tests/integration/local_stack/smoke.sh"
chmod 755 "$repo_dir/bin/local-stack"
git -C "$repo_dir" init -q

cat >"$fake_bin/docker" <<'EOF'
#!/bin/sh
case "$1 $2" in
  'context show') printf '%s\n' 'desktop-linux'; exit 0 ;;
  'context inspect') printf '%s\n' '[{"Endpoints":{"docker":{"Host":"unix:///tmp/docker.sock"}}}]'; exit 0 ;;
  'compose version') printf '%s\n' '2.35.0'; exit 0 ;;
esac
case " $* " in
  *' config --no-env-resolution --quiet '*) exit 0 ;;
  *' pull --quiet '*) exit 0 ;;
  *' up --detach '*) exit 0 ;;
  *' run --rm '*'/smoke/smoke.sh spicedb-ready '*)
    printf '%s\n' 'local component-fixture compatibility: pass'
    exit 0
    ;;
  *' ps --all --format json '*)
    printf '%s\n' \
      '{"ID":"container-migrate","Name":"fixture-kratos-migrate-1","Service":"kratos-migrate","State":"exited","Health":"","ExitCode":0}' \
      '{"ID":"container-kratos","Name":"fixture-kratos-1","Service":"kratos","State":"running","Health":"healthy","ExitCode":0}' \
      '{"ID":"container-spicedb","Name":"fixture-spicedb-1","Service":"spicedb","State":"running","Health":"","ExitCode":0}' \
      '{"ID":"container-bootstrap","Name":"fixture-local-stack-bootstrap-1","Service":"local-stack-bootstrap","State":"exited","Health":"","ExitCode":1}'
    exit 0
    ;;
  *' network ls '*--format*) printf '%s\n' "$FAKE_PROJECT"'_local-internal'; exit 0 ;;
  *' volume ls '*--format*) printf '%s\n' "$FAKE_PROJECT"'_kratos-sqlite'; exit 0 ;;
  *) printf 'unexpected fake docker invocation: %s\n' "$*" >&2; exit 64 ;;
esac
EOF
cat >"$fake_bin/ps" <<'EOF'
#!/bin/sh
printf '%s\n' "${FAKE_PS_FINGERPRINT:-Thu Aug 14 20:00:00 2026}"
EOF
cat >"$fake_bin/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod 755 "$fake_bin/docker" "$fake_bin/ps" "$fake_bin/sleep"

PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >/dev/null || fail 'fixture initialization failed'
project=$(jq -r '.compose_project' "$repo_dir/deploy/local/.local-stack-state.json")
set +e
FAKE_PROJECT="$project" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" up >"$test_root/output" 2>&1
up_status=$?
set -e
[ "$up_status" -ne 0 ] || fail 'injected startup failure unexpectedly succeeded'
grep -Fq 'component readiness or fixture bootstrap failed' "$test_root/output" ||
  fail 'startup failure did not reach the bootstrap-specific gate'

jq -e '
  .phase == "startup-failed" and
  (.resources.containers | length) == 4 and
  (.resources.networks | length) == 1 and
  (.resources.volumes | length) == 1 and
  .migration.completed == false and
  .bootstrap.completed == false
' "$repo_dir/deploy/local/.local-stack-state.json" >/dev/null ||
  fail 'startup failure did not retain exact recoverable resource provenance'

[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'startup failure retained the lifecycle lock'
[ -f "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'startup failure removed credentials'

printf '%s\n' 'ok - bootstrap-specific startup failure is journaled for exact recovery'
