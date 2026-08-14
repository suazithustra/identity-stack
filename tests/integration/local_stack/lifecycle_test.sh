#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-lifecycle-test.XXXXXX")
repo_dir="$test_root/repo"
fake_bin="$test_root/bin"
docker_log="$test_root/docker.log"
docker_state="$test_root/docker-state"
trap 'rm -rf -- "$test_root"' EXIT HUP INT TERM

mkdir -p "$repo_dir/bin" "$repo_dir/deploy/local" "$repo_dir/config/upstream/kratos/local" \
  "$repo_dir/tests/integration/local_stack/fixtures" "$fake_bin" "$docker_state"
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
printf '%s\n' "$*" >>"$FAKE_DOCKER_LOG"
case "$1 $2" in
  'context show')
    printf '%s\n' 'desktop-linux'
    exit 0
    ;;
  'context inspect')
    printf '%s\n' '[{"Endpoints":{"docker":{"Host":"unix:///tmp/docker.sock"}}}]'
    exit 0
    ;;
  'compose version')
    printf '%s\n' '2.35.0'
    exit 0
    ;;
esac

case " $* " in
  *' config --no-env-resolution --quiet '*) exit 0 ;;
  *' pull --quiet '*) exit 0 ;;
  *' up --detach '*) exit 0 ;;
  *' run --rm '*'/smoke/smoke.sh spicedb-ready '*)
    printf '%s\n' 'local component-fixture compatibility: pass'
    exit 0
    ;;
  *' stop --timeout 60 '*) exit 0 ;;
  *' container ls '*--format*)
    [ -f "$FAKE_DOCKER_STATE/containers-removed" ] && exit 0
    case " $* " in
      *' --no-trunc '*) printf '%s\n' container-migrate-full container-kratos-full container-spicedb-full container-bootstrap-full ;;
      *) printf '%s\n' container-migrate container-kratos container-spicedb container-bootstrap ;;
    esac
    [ "${FAKE_DOCKER_EXTRA:-0}" = 1 ] && printf '%s\n' container-extra
    exit 0
    ;;
  *' network ls --filter '*--format*)
    [ -f "$FAKE_DOCKER_STATE/network-removed" ] || printf '%s\n' "$FAKE_NETWORK_NAME"
    exit 0
    ;;
  *' volume ls --filter '*--format*)
    [ -f "$FAKE_DOCKER_STATE/volume-removed" ] || printf '%s\n' "$FAKE_VOLUME_NAME"
    exit 0
    ;;
  *' container inspect '*)
    generation="$FAKE_GENERATION"
    [ "${FAKE_LABEL_SPOOF:-0}" = 1 ] && generation='spoofed-generation'
    jq -n \
      --arg project "$FAKE_PROJECT" --arg checkout "$FAKE_CHECKOUT" \
      --arg config "$FAKE_CONFIG" --arg generation "$generation" '
      ["migrate", "kratos", "spicedb", "bootstrap"] | map({
        Id: ("container-" + .),
        Name: ("/fixture-" + . + "-1"),
        Config: {Labels: {
          "com.docker.compose.project": $project,
          "dev.identity-stack.profile": "local",
          "dev.identity-stack.checkout": $checkout,
          "dev.identity-stack.config": $config,
          "dev.identity-stack.generation": $generation
        }}
      })'
    exit 0
    ;;
  *' network inspect '*)
    jq -n \
      --arg name "$FAKE_NETWORK_NAME" --arg project "$FAKE_PROJECT" --arg checkout "$FAKE_CHECKOUT" \
      --arg config "$FAKE_CONFIG" --arg generation "$FAKE_GENERATION" '[{
        Name: $name,
        Labels: {
          "com.docker.compose.project": $project,
          "dev.identity-stack.profile": "local",
          "dev.identity-stack.checkout": $checkout,
          "dev.identity-stack.config": $config,
          "dev.identity-stack.generation": $generation
        }
      }]'
    exit 0
    ;;
  *' volume inspect '*)
    jq -n \
      --arg name "$FAKE_VOLUME_NAME" --arg project "$FAKE_PROJECT" --arg checkout "$FAKE_CHECKOUT" \
      --arg config "$FAKE_CONFIG" --arg generation "$FAKE_GENERATION" '[{
        Name: $name,
        Labels: {
          "com.docker.compose.project": $project,
          "dev.identity-stack.profile": "local",
          "dev.identity-stack.checkout": $checkout,
          "dev.identity-stack.config": $config,
          "dev.identity-stack.generation": $generation
        }
      }]'
    exit 0
    ;;
  *' container rm --force '*) touch "$FAKE_DOCKER_STATE/containers-removed"; exit 0 ;;
  *' network rm '*)
    if [ "${FAKE_FAIL_NETWORK_ONCE:-0}" = 1 ] && [ ! -f "$FAKE_DOCKER_STATE/network-failure-injected" ]; then
      touch "$FAKE_DOCKER_STATE/network-failure-injected"
      exit 1
    fi
    touch "$FAKE_DOCKER_STATE/network-removed"
    exit 0
    ;;
  *' volume rm '*) touch "$FAKE_DOCKER_STATE/volume-removed"; exit 0 ;;
  *' ps --all --format json '*)
    kratos_state=running
    kratos_health=healthy
    [ "${FAKE_STATUS_MODE:-ready}" = kratos-unready ] && { kratos_state=exited; kratos_health=; }
    cat <<'JSON'
[
  {"ID":"container-migrate","Name":"fixture-kratos-migrate-1","Service":"kratos-migrate","State":"exited","Health":"","ExitCode":0},
JSON
    printf '  {"ID":"container-kratos","Name":"fixture-kratos-1","Service":"kratos","State":"%s","Health":"%s","ExitCode":0},\n' "$kratos_state" "$kratos_health"
    cat <<'JSON'
  {"ID":"container-spicedb","Name":"fixture-spicedb-1","Service":"spicedb","State":"running","Health":"","ExitCode":0},
  {"ID":"container-bootstrap","Name":"fixture-local-stack-bootstrap-1","Service":"local-stack-bootstrap","State":"exited","Health":"","ExitCode":0}
]
JSON
    exit 0
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

FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" init >/dev/null ||
  fail 'fixture initialization failed'

output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" up 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'up should complete after migration, health, and bootstrap gates'
}

state="$repo_dir/deploy/local/.local-stack-state.json"
jq -e '
  .phase == "ready" and
  (.resources.containers | map(.service) | sort) == ["kratos", "kratos-migrate", "local-stack-bootstrap", "spicedb"] and
  (.resources.networks | length) == 1 and
  (.resources.volumes | length) == 1 and
  (.migration.completed == true) and
  (.bootstrap.completed == true) and
  (.bootstrap.fixture_identity | test("^[0-9a-f]{40}$"))
' "$state" >/dev/null || fail 'up did not record ready resource and completion provenance'

awk '
  /config --no-env-resolution --quiet/ { config = NR }
  /pull --quiet/ { pull = NR }
  /up --detach/ { up = NR }
  /ps --all --format json/ { inspect = NR }
  /wait local-stack-bootstrap/ { forbidden_wait = 1 }
  END { exit !(config < pull && pull < up && up < inspect && !forbidden_wait) }
' "$docker_log" || fail 'up did not preserve validate-pull-start-wait-inspect ordering'

printf '%s\n' 'ok - up records dependency-gated aggregate readiness'

output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" status 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'status should succeed for a fully ready profile'
}
[ "$output" = "kratos: healthy
spicedb: running
bootstrap: complete
aggregate: ready" ] || fail 'status output is not the stable sanitized summary'

printf '%s\n' 'ok - status reports independent and aggregate readiness'

set +e
partial_status_output=$(FAKE_STATUS_MODE=kratos-unready FAKE_DOCKER_LOG="$docker_log" \
  FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" status 2>&1)
partial_status_code=$?
set -e
[ "$partial_status_code" -ne 0 ] || fail 'status accepted a partially ready profile'
printf '%s\n' "$partial_status_output" | grep -Fq 'kratos: unready' || fail 'status hid Kratos partial readiness'
printf '%s\n' "$partial_status_output" | grep -Fq 'spicedb: running' || fail 'status hid healthy SpiceDB state'
printf '%s\n' "$partial_status_output" | grep -Fq 'aggregate: unready' || fail 'status hid aggregate failure'

printf '%s\n' 'ok - status reports partial readiness independently and nonzero'

ready_state_snapshot="$test_root/ready-state.json"
cp "$state" "$ready_state_snapshot"
jq '.bootstrap.fixture_identity = "0000000000000000000000000000000000000000"' \
  "$ready_state_snapshot" >"$state"
log_before=$(wc -l <"$docker_log" | tr -d ' ')
set +e
stale_output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" smoke 2>&1)
stale_status=$?
set -e
[ "$stale_status" -ne 0 ] || fail 'smoke accepted a stale bootstrap fixture hash'
printf '%s\n' "$stale_output" | grep -Fq 'smoke requires current migration and bootstrap attestations' ||
  fail 'stale bootstrap failure did not identify its attestation gate'
if tail -n "+$((log_before + 1))" "$docker_log" | grep -Fq ' run --rm '; then
  fail 'stale bootstrap failure launched a functional probe'
fi
cp "$ready_state_snapshot" "$state"

printf '%s\n' 'ok - smoke refuses stale bootstrap evidence before probing'

output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" down 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'down should stop the ready profile while preserving state'
}
[ "$output" = 'Local stack stopped; state preserved.' ] || fail 'down output is not the stable preservation summary'
jq -e '
  .phase == "stopped" and
  (.resources.containers | length) == 4 and
  (.resources.networks | length) == 1 and
  (.resources.volumes | length) == 1 and
  .migration.completed == true and
  .bootstrap.completed == true
' "$state" >/dev/null || fail 'down did not preserve resource and completion provenance'
[ -f "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'down removed credentials'
[ -f "$state" ] || fail 'down removed the state journal'

printf '%s\n' 'ok - down stops services and preserves local state'

log_before=$(wc -l <"$docker_log" | tr -d ' ')
set +e
preview=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" reset 2>&1)
preview_status=$?
set -e
[ "$preview_status" -ne 0 ] || fail 'reset without confirmation succeeded'
printf '%s\n' "$preview" | grep -Fq 'Reset would permanently remove:' || fail 'reset did not preview destructive scope'
for resource_name in \
  fixture-kratos-migrate-1 fixture-kratos-1 fixture-spicedb-1 fixture-local-stack-bootstrap-1 \
  "$(jq -r '.resources.networks[0].name' "$state")" "$(jq -r '.resources.volumes[0].name' "$state")"; do
  printf '%s\n' "$preview" | grep -Fq "$resource_name" || fail "reset preview omitted $resource_name"
done
log_after=$(wc -l <"$docker_log" | tr -d ' ')
[ "$log_before" = "$log_after" ] || fail 'unconfirmed reset called Docker mutation or inspection'
[ -f "$state" ] || fail 'unconfirmed reset removed state'

printf '%s\n' 'ok - reset previews exact scope and requires confirmation'

network_name=$(jq -r '.resources.networks[0].name' "$state")
volume_name=$(jq -r '.resources.volumes[0].name' "$state")
checkout_id=$(jq -r '.checkout_id' "$state")
config_identity=$(jq -r '.config_identity' "$state")
generation=$(jq -r '.state_generation' "$state")
project=$(jq -r '.compose_project' "$state")
set +e
unsafe_output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" FAKE_DOCKER_EXTRA=1 \
  FAKE_NETWORK_NAME="$network_name" FAKE_VOLUME_NAME="$volume_name" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" reset --yes 2>&1)
unsafe_status=$?
set -e
[ "$unsafe_status" -ne 0 ] || fail 'reset ignored an extra project container'
[ ! -e "$docker_state/containers-removed" ] || fail 'ambiguous reset removed containers'
[ ! -e "$docker_state/network-removed" ] || fail 'ambiguous reset removed the network'
[ ! -e "$docker_state/volume-removed" ] || fail 'ambiguous reset removed the volume'
[ -f "$state" ] || fail 'ambiguous reset removed state'
printf '%s\n' "$unsafe_output" | grep -Fq 'resource inventory does not match' || fail 'ambiguous reset did not identify its gate'

printf '%s\n' 'ok - reset refuses extra project resources before deletion'

set +e
spoof_output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" FAKE_LABEL_SPOOF=1 \
  FAKE_NETWORK_NAME="$network_name" FAKE_VOLUME_NAME="$volume_name" FAKE_CHECKOUT="$checkout_id" \
  FAKE_CONFIG="$config_identity" FAKE_GENERATION="$generation" FAKE_PROJECT="$project" \
  PATH="$fake_bin:$PATH" "$repo_dir/bin/local-stack" reset --yes 2>&1)
spoof_status=$?
set -e
[ "$spoof_status" -ne 0 ] || fail 'reset accepted spoofed resource ownership labels'
[ ! -e "$docker_state/containers-removed" ] || fail 'spoofed-label reset removed containers'
[ ! -e "$docker_state/network-removed" ] || fail 'spoofed-label reset removed the network'
[ ! -e "$docker_state/volume-removed" ] || fail 'spoofed-label reset removed the volume'
[ -f "$state" ] || fail 'spoofed-label reset removed state'
printf '%s\n' "$spoof_output" | grep -Fq 'ownership labels do not match' || fail 'spoofed-label reset did not identify its gate'

printf '%s\n' 'ok - reset refuses spoofed ownership labels before deletion'

printf '%s\n' '# changed configuration requires a journal-owned reset' >>"$repo_dir/deploy/local/compose.yaml"
set +e
partial_output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" FAKE_FAIL_NETWORK_ONCE=1 \
  FAKE_NETWORK_NAME="$network_name" FAKE_VOLUME_NAME="$volume_name" FAKE_CHECKOUT="$checkout_id" \
  FAKE_CONFIG="$config_identity" FAKE_GENERATION="$generation" FAKE_PROJECT="$project" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" reset --yes 2>&1)
partial_status=$?
set -e
[ "$partial_status" -ne 0 ] || fail 'injected partial reset unexpectedly succeeded'
printf '%s\n' "$partial_output" | grep -Fq 'reset can be retried from its journal' ||
  fail 'partial reset did not identify resumable recovery'
jq -e '
  .phase == "resetting" and
  (.resources.containers | length) == 0 and
  (.resources.networks | length) == 1 and
  (.resources.volumes | length) == 1
' "$state" >/dev/null || fail 'partial reset did not checkpoint exact remaining work'
[ -f "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'partial reset removed credentials before Docker resources'
if FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" up >"$test_root/resetting-up-output" 2>&1; then
  fail 'up accepted a resetting journal'
fi

printf '%s\n' 'ok - partial reset checkpoints and blocks normal lifecycle work'

output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" \
  FAKE_NETWORK_NAME="$network_name" FAKE_VOLUME_NAME="$volume_name" FAKE_CHECKOUT="$checkout_id" \
  FAKE_CONFIG="$config_identity" FAKE_GENERATION="$generation" FAKE_PROJECT="$project" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" reset --yes 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'confirmed reset should resume and remove only journal-owned resources and local files'
}
printf '%s\n' "$output" | grep -Fq 'Reset would permanently remove:' || fail 'confirmed reset omitted its final preview'
[ "$(printf '%s\n' "$output" | tail -n 1)" = 'Local stack reset complete.' ] || fail 'confirmed reset output is not the stable completion summary'
[ -f "$docker_state/containers-removed" ] || fail 'confirmed reset did not remove exact containers'
[ -f "$docker_state/network-removed" ] || fail 'confirmed reset did not remove the exact network'
[ -f "$docker_state/volume-removed" ] || fail 'confirmed reset did not remove the exact volume'
[ ! -e "$repo_dir/deploy/local/.local-stack-credentials.env" ] || fail 'confirmed reset retained credentials'
[ ! -e "$state" ] || fail 'confirmed reset retained state'
[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'confirmed reset retained the lifecycle lock'

printf '%s\n' 'ok - confirmed reset removes the exact profile and paired secrets'

jq '
  .phase = "resetting" |
  .resources = {containers: [], networks: [], volumes: []}
' "$ready_state_snapshot" >"$state"
chmod 600 "$state"
output=$(FAKE_DOCKER_LOG="$docker_log" FAKE_DOCKER_STATE="$docker_state" \
  FAKE_NETWORK_NAME="$network_name" FAKE_VOLUME_NAME="$volume_name" FAKE_CHECKOUT="$checkout_id" \
  FAKE_CONFIG="$config_identity" FAKE_GENERATION="$generation" FAKE_PROJECT="$project" PATH="$fake_bin:$PATH" \
  "$repo_dir/bin/local-stack" reset --yes 2>&1) || {
  printf '%s\n' "$output" >&2
  fail 'reset should finish from an empty resetting journal after credentials were removed'
}
[ ! -e "$state" ] || fail 'state-only reset finalization retained the journal'
[ ! -e "$repo_dir/deploy/local/.local-stack.lock" ] || fail 'state-only reset finalization retained the lifecycle lock'

printf '%s\n' 'ok - reset resumes finalization after credential removal'
