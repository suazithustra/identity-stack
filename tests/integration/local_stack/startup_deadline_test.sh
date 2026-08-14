#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-startup-deadline-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT HUP INT TERM

make_fixture() {
  fixture_name=$1
  readiness_timeout=$2
  aggregate_timeout=$3
  spicedb_timeout=$4
  repo_dir="$test_root/$fixture_name/repo"
  fake_bin="$test_root/$fixture_name/bin"
  docker_log="$test_root/$fixture_name/docker.log"
  mkdir -p "$repo_dir/bin" "$repo_dir/deploy/local" "$repo_dir/config/upstream/kratos/local" \
    "$repo_dir/tests/integration/local_stack/fixtures" "$fake_bin"
  sed \
    -e "s/^KRATOS_READINESS_TIMEOUT=60$/KRATOS_READINESS_TIMEOUT=$readiness_timeout/" \
    -e "s/^SPICEDB_HEALTH_TIMEOUT=60$/SPICEDB_HEALTH_TIMEOUT=$spicedb_timeout/" \
    -e "s/^AGGREGATE_UP_TIMEOUT=600$/AGGREGATE_UP_TIMEOUT=$aggregate_timeout/" \
    "$ROOT_DIR/bin/local-stack" >"$repo_dir/bin/local-stack"
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
  *' pull --quiet '*) exit 0 ;;
  *' up --detach '*) exit 0 ;;
  *' run --rm '*'/smoke/smoke.sh spicedb-ready '*)
    exec /bin/sleep "${FAKE_SPICEDB_PROBE_SLEEP:-0}"
    ;;
  *' ps --all --format json '*)
    printf '%s\n' '[
      {"ID":"container-migrate","Name":"fixture-kratos-migrate-1","Service":"kratos-migrate","State":"exited","Health":"","ExitCode":0},
      {"ID":"container-kratos","Name":"fixture-kratos-1","Service":"kratos","State":"running","Health":"'"${FAKE_KRATOS_HEALTH:-starting}"'","ExitCode":0},
      {"ID":"container-spicedb","Name":"fixture-spicedb-1","Service":"spicedb","State":"running","Health":"","ExitCode":0}
    ]'
    exit 0
    ;;
  *' network ls --filter '*--format*) printf '%s\n' fixture-network; exit 0 ;;
  *' volume ls --filter '*--format*) printf '%s\n' fixture-volume; exit 0 ;;
  *) printf 'unexpected fake docker invocation: %s\n' "$*" >&2; exit 64 ;;
esac
EOF
  cat >"$fake_bin/ps" <<'EOF'
#!/bin/sh
printf '%s\n' 'Thu Aug 14 20:00:00 2026'
EOF
  chmod 755 "$fake_bin/docker" "$fake_bin/ps"
}

run_bounded_up() {
  repo_dir=$1
  fake_bin=$2
  docker_log=$3
  output_file=$4
  kratos_health=$5
  spicedb_probe_sleep=$6
  FAKE_DOCKER_LOG="$docker_log" FAKE_KRATOS_HEALTH="$kratos_health" \
    FAKE_SPICEDB_PROBE_SLEEP="$spicedb_probe_sleep" PATH="$fake_bin:$PATH" \
    "$repo_dir/bin/local-stack" init >/dev/null || fail 'fixture initialization failed'
  FAKE_DOCKER_LOG="$docker_log" FAKE_KRATOS_HEALTH="$kratos_health" \
    FAKE_SPICEDB_PROBE_SLEEP="$spicedb_probe_sleep" PATH="$fake_bin:$PATH" \
    "$repo_dir/bin/local-stack" up >"$output_file" 2>&1 &
  up_pid=$!
  watchdog_ticks=0
  while kill -0 "$up_pid" 2>/dev/null && [ "$watchdog_ticks" -lt 100 ]; do
    /bin/sleep 0.1
    watchdog_ticks=$((watchdog_ticks + 1))
  done
  if kill -0 "$up_pid" 2>/dev/null; then
    kill -TERM "$up_pid"
    wait "$up_pid" 2>/dev/null || true
    return 124
  fi
  wait "$up_pid"
  up_status=$?
  return "$up_status"
}

make_fixture stage 1 10 10
stage_repo="$test_root/stage/repo"
stage_bin="$test_root/stage/bin"
stage_log="$test_root/stage/docker.log"
set +e
run_bounded_up "$stage_repo" "$stage_bin" "$stage_log" "$test_root/stage-output" starting 0
stage_status=$?
set -e
[ "$stage_status" -ne 0 ] || fail 'stalled Kratos readiness unexpectedly succeeded'
[ "$stage_status" -ne 124 ] || fail 'Kratos readiness ignored its absolute stage deadline'
grep -Fq 'Kratos readiness timed out' "$test_root/stage-output" ||
  fail 'Kratos readiness deadline did not identify its stage'

printf '%s\n' 'ok - Kratos readiness uses an absolute stage deadline'

make_fixture aggregate 10 1 10
aggregate_repo="$test_root/aggregate/repo"
aggregate_bin="$test_root/aggregate/bin"
aggregate_log="$test_root/aggregate/docker.log"
set +e
run_bounded_up "$aggregate_repo" "$aggregate_bin" "$aggregate_log" "$test_root/aggregate-output" starting 0
aggregate_status=$?
set -e
[ "$aggregate_status" -ne 0 ] || fail 'aggregate startup deadline unexpectedly succeeded'
[ "$aggregate_status" -ne 124 ] || fail 'aggregate startup ignored its absolute deadline'
grep -Fq 'aggregate up timed out' "$test_root/aggregate-output" ||
  fail 'aggregate startup deadline did not identify its boundary'

printf '%s\n' 'ok - aggregate startup uses one absolute deadline'

make_fixture spicedb 10 10 1
spicedb_repo="$test_root/spicedb/repo"
spicedb_bin="$test_root/spicedb/bin"
spicedb_log="$test_root/spicedb/docker.log"
set +e
run_bounded_up "$spicedb_repo" "$spicedb_bin" "$spicedb_log" "$test_root/spicedb-output" healthy 20
spicedb_status=$?
set -e
[ "$spicedb_status" -ne 0 ] || fail 'stalled SpiceDB health unexpectedly succeeded'
[ "$spicedb_status" -ne 124 ] || fail 'SpiceDB health ignored its absolute stage deadline'
grep -Fq 'SpiceDB health timed out' "$test_root/spicedb-output" || {
  sed -n '1,20p' "$test_root/spicedb-output" >&2
  fail 'SpiceDB health deadline did not identify its stage'
}

printf '%s\n' 'ok - SpiceDB health uses an absolute stage deadline'
