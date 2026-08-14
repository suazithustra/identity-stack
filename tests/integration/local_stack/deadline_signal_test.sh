#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-deadline-signal-test.XXXXXX")
repo_dir="$test_root/repo"
fake_bin="$test_root/bin"
docker_log="$test_root/docker.log"
pull_started="$test_root/pull-started"
trap 'rm -rf -- "$test_root"' EXIT HUP INT TERM

mkdir -p "$repo_dir/bin" "$repo_dir/deploy/local" "$repo_dir/config/upstream/kratos/local" \
  "$repo_dir/tests/integration/local_stack/fixtures" "$fake_bin"
sed 's/^IMAGE_PULL_TIMEOUT=300$/IMAGE_PULL_TIMEOUT=1/' "$ROOT_DIR/bin/local-stack" >"$repo_dir/bin/local-stack"
cp "$ROOT_DIR/deploy/local/.env.example" "$repo_dir/deploy/local/.env.example"
cp "$ROOT_DIR/deploy/local/compose.yaml" "$repo_dir/deploy/local/compose.yaml"
cp -R "$ROOT_DIR/config/upstream/kratos/local/." "$repo_dir/config/upstream/kratos/local/"
cp -R "$ROOT_DIR/tests/integration/local_stack/fixtures/." "$repo_dir/tests/integration/local_stack/fixtures/"
cp "$ROOT_DIR/tests/integration/local_stack/smoke.sh" "$repo_dir/tests/integration/local_stack/smoke.sh"
chmod 755 "$repo_dir/bin/local-stack"
git -C "$repo_dir" init -q

cat >"$fake_bin/docker" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_DOCKER_LOG"
case "$1 $2" in
  'context show') printf '%s\n' desktop-linux; exit 0 ;;
  'context inspect') printf '%s\n' '[{"Endpoints":{"docker":{"Host":"unix:///tmp/docker.sock"}}}]'; exit 0 ;;
  'compose version') printf '%s\n' 2.35.0; exit 0 ;;
esac
case " $* " in
  *' config --no-env-resolution --quiet '*) exit 0 ;;
  *' pull --quiet '*)
    : >"$FAKE_PULL_STARTED"
    exec /bin/sleep "${FAKE_PULL_SLEEP:-5}"
    ;;
  *) printf 'unexpected fake docker invocation: %s\n' "$*" >&2; exit 64 ;;
esac
EOF
cat >"$fake_bin/ps" <<'EOF'
#!/bin/sh
printf '%s\n' 'Thu Aug 14 20:00:00 2026'
EOF
chmod 755 "$fake_bin/docker" "$fake_bin/ps"

FAKE_DOCKER_LOG="$docker_log" FAKE_PULL_STARTED="$pull_started" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" init >/dev/null || fail 'fixture initialization failed'

set +e
FAKE_DOCKER_LOG="$docker_log" FAKE_PULL_STARTED="$pull_started" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" up >"$test_root/timeout-output" 2>&1
timeout_status=$?
set -e
[ "$timeout_status" -ne 0 ] || fail 'blocked image acquisition ignored its deadline'
grep -Fq 'pinned image acquisition failed or timed out' "$test_root/timeout-output" ||
  fail 'deadline failure did not identify image acquisition'
[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'deadline failure retained the lifecycle lock'

printf '%s\n' 'ok - image acquisition deadline fails closed and releases the lock'

rm -f "$pull_started"
FAKE_DOCKER_LOG="$docker_log" FAKE_PULL_STARTED="$pull_started" FAKE_PULL_SLEEP=20 \
  PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" up >"$test_root/signal-output" 2>&1 &
up_pid=$!
attempt=0
while [ ! -e "$pull_started" ] && [ "$attempt" -lt 50 ]; do
  /bin/sleep 0.1
  attempt=$((attempt + 1))
done
[ -e "$pull_started" ] || fail 'signal test did not reach image acquisition'
kill -TERM "$up_pid"
set +e
wait "$up_pid"
signal_status=$?
set -e
[ "$signal_status" -ne 0 ] || fail 'TERM allowed lifecycle mutation to report success'
[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'TERM retained the lifecycle lock'
if grep -Fq ' up --detach ' "$docker_log"; then
  fail 'TERM allowed lifecycle mutation to continue after lock release'
fi

printf '%s\n' 'ok - termination stops lifecycle mutation before releasing ownership'
