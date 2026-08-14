#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

file_mode() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

new_fixture() {
  test_root=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-init-test.XXXXXX")
  repo_dir="$test_root/repo"
  fake_bin="$test_root/bin"
  mkdir -p "$repo_dir/bin" "$repo_dir/deploy/local" "$repo_dir/config/upstream/kratos/local" \
    "$repo_dir/tests/integration/local_stack/fixtures" "$fake_bin"

  if [ ! -x "$ROOT_DIR/bin/local-stack" ]; then
    fail 'bin/local-stack is missing or not executable'
  fi
  if [ ! -f "$ROOT_DIR/deploy/local/.env.example" ]; then
    fail 'deploy/local/.env.example is missing'
  fi

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
  'context show')
    printf '%s\n' 'desktop-linux'
    ;;
  'context inspect')
    printf '%s\n' '[{"Endpoints":{"docker":{"Host":"unix:///tmp/docker.sock"}}}]'
    ;;
  'compose version')
    printf '%s\n' '2.35.0'
    ;;
  *)
    printf 'unexpected fake docker invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
EOF
  cat >"$fake_bin/ps" <<'EOF'
#!/bin/sh
printf '%s\n' "${FAKE_PS_FINGERPRINT:-Thu Aug 14 20:00:00 2026}"
EOF
  chmod 755 "$fake_bin/docker" "$fake_bin/ps"
}

cleanup() {
  if [ -n "${test_root:-}" ] && [ -d "$test_root" ]; then
    rm -rf -- "$test_root"
  fi
}

trap cleanup EXIT HUP INT TERM

new_fixture

output=$(PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'init should succeed in a safe local fixture'
}

credentials="$repo_dir/deploy/local/.local-stack-credentials.env"
state="$repo_dir/deploy/local/.local-stack-state.json"

[ -f "$credentials" ] || fail 'init did not create the credential file'
[ -f "$state" ] || fail 'init did not create the state journal'
[ "$(file_mode "$credentials")" = '600' ] || fail 'credential file mode is not 600'
[ "$(file_mode "$state")" = '600' ] || fail 'state journal mode is not 600'

cipher=$(sed -n 's/^SECRETS_CIPHER=//p' "$credentials")
cookie=$(sed -n 's/^SECRETS_COOKIE=//p' "$credentials")
pagination=$(sed -n 's/^SECRETS_PAGINATION=//p' "$credentials")
spicedb=$(sed -n 's/^SPICEDB_GRPC_PRESHARED_KEY=//p' "$credentials")

printf '%s\n' "$cipher" | grep -Eq '^[A-Za-z0-9_-]{32}$' || fail 'cipher secret has the wrong format'
for value in "$cookie" "$pagination" "$spicedb"; do
  printf '%s\n' "$value" | grep -Eq '^[A-Za-z0-9_-]{43}$' || fail 'base64url credential has the wrong format'
done

[ "$cipher" != "$cookie" ] || fail 'generated credentials are not distinct'
[ "$cipher" != "$pagination" ] || fail 'generated credentials are not distinct'
[ "$cipher" != "$spicedb" ] || fail 'generated credentials are not distinct'
[ "$cookie" != "$pagination" ] || fail 'generated credentials are not distinct'
[ "$cookie" != "$spicedb" ] || fail 'generated credentials are not distinct'
[ "$pagination" != "$spicedb" ] || fail 'generated credentials are not distinct'

jq -e '
  .schema_version == 1 and
  (.canonical_checkout | type == "string" and length > 0) and
  (.checkout_id | test("^[0-9a-f]{12}$")) and
  (.config_identity | test("^[0-9a-f]{40}$")) and
  (.state_generation | test("^[A-Za-z0-9_-]{43}$")) and
  (.compose_project | test("^identity-stack-local-[0-9a-f]{12}$")) and
  .phase == "initialized" and
  .resources == {"containers": [], "networks": [], "volumes": []}
' "$state" >/dev/null || fail 'state journal does not satisfy the initialization contract'

for value in "$cipher" "$cookie" "$pagination" "$spicedb"; do
  case "$output" in
    *"$value"*) fail 'init printed a generated credential' ;;
  esac
  if grep -Fq "$value" "$state"; then
    fail 'state journal contains a generated credential'
  fi
done

printf '%s\n' 'ok - init creates safe local credentials and provenance'

cleanup
test_root=
new_fixture

mkdir "$repo_dir/deploy/local/.local-stack.lock"
if PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/output" 2>&1; then
  fail 'init succeeded while an ambiguous lifecycle lock existed'
fi
[ ! -e "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'locked init created credentials'
[ ! -e "$repo_dir/deploy/local/.local-stack-state.json" ] || fail 'locked init created a state journal'

printf '%s\n' 'ok - ambiguous lifecycle lock blocks initialization without writes'

cleanup
test_root=
new_fixture

lock_dir="$repo_dir/deploy/local/.local-stack.lock"
mkdir -m 700 "$lock_dir"
jq -n \
  --arg canonical_checkout "$(CDPATH='' cd -- "$repo_dir" && pwd -P)" \
  --arg config_identity '0123456789abcdef0123456789abcdef01234567' \
  --arg state_generation 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' \
  --arg process_start_fingerprint '2026-08-14T00:00:00Z-stale' \
  --arg acquired_at '2026-08-14T00:00:00Z' \
  --arg ownership_token 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' \
  '{
    canonical_checkout: $canonical_checkout,
    config_identity: $config_identity,
    state_generation: $state_generation,
    pid: 99999999,
    process_start_fingerprint: $process_start_fingerprint,
    acquired_at: $acquired_at,
    ownership_token: $ownership_token
  }' >"$lock_dir/owner.json"
chmod 600 "$lock_dir/owner.json"

output=$(PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'init should recover a valid lock whose owner PID is absent'
}
[ ! -e "$lock_dir" ] || fail 'successful init left the lifecycle lock behind'
[ -f "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'stale-lock recovery did not initialize credentials'
[ -f "$repo_dir/deploy/local/.local-stack-state.json" ] || fail 'stale-lock recovery did not initialize state'

printf '%s\n' 'ok - provably stale lifecycle lock is replaced safely'

cleanup
test_root=
new_fixture

lock_dir="$repo_dir/deploy/local/.local-stack.lock"
mkdir -m 700 "$lock_dir"
jq -n \
  --arg canonical_checkout "$(CDPATH='' cd -- "$repo_dir" && pwd -P)" \
  --arg config_identity '0123456789abcdef0123456789abcdef01234567' \
  --arg state_generation 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' \
  --arg process_start_fingerprint 'Mon Jan 01 00:00:00 2001' \
  --arg acquired_at '2026-08-14T00:00:00Z' \
  --arg ownership_token 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' \
  --argjson pid "$$" '
  {
    canonical_checkout: $canonical_checkout,
    config_identity: $config_identity,
    state_generation: $state_generation,
    pid: $pid,
    process_start_fingerprint: $process_start_fingerprint,
    acquired_at: $acquired_at,
    ownership_token: $ownership_token
  }' >"$lock_dir/owner.json"
chmod 600 "$lock_dir/owner.json"

output=$(PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'init should recover a lock whose PID was reused by a different process start'
}
[ ! -e "$lock_dir" ] || fail 'PID-reuse recovery retained the lifecycle lock'

printf '%s\n' 'ok - PID reuse is distinguished from a live lifecycle owner'

credentials="$repo_dir/deploy/local/.local-stack-credentials.env"
state="$repo_dir/deploy/local/.local-stack-state.json"
credentials_before=$(git hash-object "$credentials")
state_before=$(git hash-object "$state")
if PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/repeat-output" 2>&1; then
  fail 'repeat init overwrote existing local state'
fi
[ "$(git hash-object "$credentials")" = "$credentials_before" ] || fail 'repeat init changed credentials'
[ "$(git hash-object "$state")" = "$state_before" ] || fail 'repeat init changed the state journal'
[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'repeat init left the lifecycle lock behind'

printf '%s\n' 'ok - repeat initialization preserves existing state'

for override_name in DOCKER_HOST DOCKER_CONTEXT DOCKER_DEFAULT_PLATFORM COMPOSE_FILE COMPOSE_PROJECT_NAME COMPOSE_PROFILES COMPOSE_ENV_FILES COMPOSE_PATH_SEPARATOR COMPOSE_IGNORE_ORPHANS COMPOSE_REMOVE_ORPHANS COMPOSE_EXPERIMENTAL SECRETS_CIPHER SECRETS_COOKIE SECRETS_PAGINATION SPICEDB_GRPC_PRESHARED_KEY; do
  cleanup
  test_root=
  new_fixture
  if env "$override_name=hostile-value" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/override-output" 2>&1; then
    fail "init accepted ambient override $override_name"
  fi
  [ ! -e "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail "$override_name rejection created credentials"
  [ ! -e "$repo_dir/deploy/local/.local-stack-state.json" ] || fail "$override_name rejection created state"
  [ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail "$override_name rejection created a lock"
done

printf '%s\n' 'ok - behavior-changing Docker and Compose overrides fail before writes'

cleanup
test_root=
new_fixture
sed -i.bak 's#unix:///tmp/docker.sock#tcp://example.invalid:2376#' "$fake_bin/docker"
if PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/remote-output" 2>&1; then
  fail 'init accepted a remote Docker endpoint'
fi
[ ! -e "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'remote-context rejection created credentials'
[ ! -e "$repo_dir/deploy/local/.local-stack-state.json" ] || fail 'remote-context rejection created state'

printf '%s\n' 'ok - remote Docker endpoint fails before writes'

cleanup
test_root=
new_fixture
sed -i.bak 's/2\.35\.0/2.34.9/' "$fake_bin/docker"
if PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/version-output" 2>&1; then
  fail 'init accepted Docker Compose below the feature floor'
fi
[ ! -e "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'version rejection created credentials'
[ ! -e "$repo_dir/deploy/local/.local-stack-state.json" ] || fail 'version rejection created state'

printf '%s\n' 'ok - Docker Compose feature floor is enforced before writes'

cleanup
test_root=
new_fixture
outside_target="$test_root/outside-target"
printf '%s\n' 'unchanged' >"$outside_target"
ln -s "$outside_target" "$repo_dir/deploy/local/.local-stack-credentials.env"
if PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/symlink-output" 2>&1; then
  fail 'init accepted a symlink credential path'
fi
[ "$(sed -n '1p' "$outside_target")" = 'unchanged' ] || fail 'symlink rejection modified the external target'
[ ! -e "$repo_dir/deploy/local/.local-stack-state.json" ] || fail 'symlink rejection created state'

printf '%s\n' 'ok - symlink credential path fails without external writes'

cleanup
test_root=
new_fixture
mkfifo "$repo_dir/deploy/local/.local-stack-state.json"
if PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/fifo-output" 2>&1; then
  fail 'init accepted a FIFO state path'
fi
[ ! -e "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'FIFO rejection created credentials'
[ -p "$repo_dir/deploy/local/.local-stack-state.json" ] || fail 'FIFO rejection changed the unsafe target'

printf '%s\n' 'ok - FIFO state path fails without writes'

cleanup
test_root=
new_fixture
PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/concurrent-1" 2>&1 &
pid_one=$!
PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >"$test_root/concurrent-2" 2>&1 &
pid_two=$!
set +e
wait "$pid_one"
status_one=$?
wait "$pid_two"
status_two=$?
set -e
if [ "$status_one" -eq 0 ] && [ "$status_two" -eq 0 ]; then
  fail 'both concurrent initializers succeeded'
fi
if [ "$status_one" -ne 0 ] && [ "$status_two" -ne 0 ]; then
  fail 'both concurrent initializers failed'
fi
[ -f "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'concurrent init did not leave credentials'
jq -e '.phase == "initialized"' "$repo_dir/deploy/local/.local-stack-state.json" >/dev/null || fail 'concurrent init left invalid state'
[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'concurrent init left the lifecycle lock behind'
if find "$repo_dir/deploy/local" -maxdepth 1 -name '.local-stack-*.tmp.*' -print | grep -q .; then
  fail 'concurrent init left a temporary file behind'
fi

printf '%s\n' 'ok - concurrent initialization yields one complete owner'
