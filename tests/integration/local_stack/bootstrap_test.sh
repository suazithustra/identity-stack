#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

test_root=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-bootstrap-test.XXXXXX")
repo_dir="$test_root/repo"
fake_bin="$test_root/bin"
curl_log="$test_root/curl.log"
model="$test_root/model.json"
trap 'rm -rf -- "$test_root"' EXIT HUP INT TERM

mkdir -p "$repo_dir/deploy/local" "$repo_dir/config/upstream/kratos/local" \
  "$repo_dir/tests/integration/local_stack" "$fake_bin"
cp "$ROOT_DIR/deploy/local/compose.yaml" "$repo_dir/deploy/local/compose.yaml"
cp "$ROOT_DIR/deploy/local/.env.example" "$repo_dir/deploy/local/.local-stack-credentials.env"
cp -R "$ROOT_DIR/config/upstream/kratos/local/." "$repo_dir/config/upstream/kratos/local/"
cp -R "$ROOT_DIR/tests/integration/local_stack/fixtures" "$repo_dir/tests/integration/local_stack/fixtures"
cp "$ROOT_DIR/tests/integration/local_stack/smoke.sh" "$repo_dir/tests/integration/local_stack/smoke.sh"
chmod 600 "$repo_dir/deploy/local/.local-stack-credentials.env"

cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh

printf '%s\n' "$*" >>"$FAKE_CURL_LOG"

case " $* " in
  *' http://spicedb:8443/v1/schema/read '*)
    case " $* " in
      *' --write-out '*) printf '%s' '404'; exit 0 ;;
      *) exit 22 ;;
    esac
    ;;
  *' http://spicedb:8443/v1/schema/write '*) exit 0 ;;
  *' http://spicedb:8443/v1/relationships/write '*) exit 0 ;;
  *) exit 64 ;;
esac
EOF

cat >"$fake_bin/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF

chmod 755 "$fake_bin/curl" "$fake_bin/sleep"

LOCAL_STACK_CHECKOUT_ID=0123456789ab \
LOCAL_STACK_CONFIG_IDENTITY=0123456789abcdef0123456789abcdef01234567 \
LOCAL_STACK_STATE_GENERATION=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
docker compose -f "$repo_dir/deploy/local/compose.yaml" \
  config --no-env-resolution --format json >"$model" ||
  fail 'Docker Compose rejected the tracked bootstrap model'

bootstrap_command=$(jq -er '.services["local-stack-bootstrap"].command[0]' "$model" | sed 's/\$\$/\$/g') ||
  fail 'resolved model omitted the bootstrap command'

set +e
FAKE_CURL_LOG="$curl_log" \
SPICEDB_GRPC_PRESHARED_KEY=TEST_ONLY_PRESHARED_KEY \
PATH="$fake_bin:$PATH" \
/bin/sh -ec "$bootstrap_command" >"$test_root/output" 2>&1
bootstrap_status=$?
set -e

[ "$bootstrap_status" -eq 0 ] || {
  sed -n '1,80p' "$test_root/output" >&2
  fail 'bootstrap rejected authenticated SpiceDB readiness before the first schema exists'
}

grep -Fq 'http://spicedb:8443/v1/schema/write' "$curl_log" ||
  fail 'bootstrap did not write the declared schema after empty-datastore readiness'
grep -Fq 'http://spicedb:8443/v1/relationships/write' "$curl_log" ||
  fail 'bootstrap did not write the declared relationship after empty-datastore readiness'

printf '%s\n' 'ok - empty SpiceDB schema is accepted as authenticated readiness'
