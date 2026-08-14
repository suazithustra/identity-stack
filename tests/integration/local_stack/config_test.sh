#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)
SOURCE_COMPOSE_FILE="$ROOT_DIR/deploy/local/compose.yaml"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

[ -f "$SOURCE_COMPOSE_FILE" ] || fail 'deploy/local/compose.yaml is missing'

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/identity-stack-config-test.XXXXXX")
trap 'rm -rf -- "$tmp_dir"' EXIT HUP INT TERM
model="$tmp_dir/model.json"
resolved_model="$tmp_dir/resolved-model.json"
quiet_output="$tmp_dir/quiet-output"
mkdir -p "$tmp_dir/repo/deploy/local" "$tmp_dir/repo/config/upstream/kratos/local" \
  "$tmp_dir/repo/tests/integration/local_stack/fixtures"
cp "$SOURCE_COMPOSE_FILE" "$tmp_dir/repo/deploy/local/compose.yaml"
cp -R "$ROOT_DIR/config/upstream/kratos/local/." "$tmp_dir/repo/config/upstream/kratos/local/"
cp -R "$ROOT_DIR/tests/integration/local_stack/fixtures/." "$tmp_dir/repo/tests/integration/local_stack/fixtures/"
cat >"$tmp_dir/repo/deploy/local/.local-stack-credentials.env" <<'EOF'
SECRETS_CIPHER=CANARY_CIPHER_NOT_SECRET
SECRETS_COOKIE=CANARY_COOKIE_NOT_SECRET
SECRETS_PAGINATION=CANARY_PAGINATION_NOT_SECRET
SPICEDB_GRPC_PRESHARED_KEY=CANARY_SPICEDB_NOT_SECRET
EOF
chmod 600 "$tmp_dir/repo/deploy/local/.local-stack-credentials.env"
COMPOSE_FILE="$tmp_dir/repo/deploy/local/compose.yaml"

LOCAL_STACK_CHECKOUT_ID=0123456789ab \
LOCAL_STACK_CONFIG_IDENTITY=0123456789abcdef0123456789abcdef01234567 \
LOCAL_STACK_STATE_GENERATION=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
docker compose -f "$COMPOSE_FILE" config --no-env-resolution --quiet >"$quiet_output" ||
  fail 'Docker Compose rejected the live credential model during quiet validation'
[ ! -s "$quiet_output" ] || fail 'quiet model validation retained output'

LOCAL_STACK_CHECKOUT_ID=0123456789ab \
LOCAL_STACK_CONFIG_IDENTITY=0123456789abcdef0123456789abcdef01234567 \
LOCAL_STACK_STATE_GENERATION=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
docker compose -f "$COMPOSE_FILE" config --format json >"$resolved_model" ||
  fail 'Docker Compose rejected the positive-control credential model'
grep -Fq 'CANARY_' "$resolved_model" || fail 'secret-render scan positive control did not expose its canary'

cp "$ROOT_DIR/deploy/local/.env.example" "$tmp_dir/repo/deploy/local/.local-stack-credentials.env"
chmod 600 "$tmp_dir/repo/deploy/local/.local-stack-credentials.env"

LOCAL_STACK_CHECKOUT_ID=0123456789ab \
LOCAL_STACK_CONFIG_IDENTITY=0123456789abcdef0123456789abcdef01234567 \
LOCAL_STACK_STATE_GENERATION=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
docker compose -f "$COMPOSE_FILE" config --no-env-resolution --format json >"$model" ||
  fail 'Docker Compose rejected the tracked model'

grep -Fq 'CANARY_' "$quiet_output" && fail 'quiet model validation retained a credential value'
grep -Fq 'CANARY_' "$model" && fail 'structural model retained a prior credential canary'

jq -e '
  (.services | keys | sort) == ["kratos", "kratos-migrate", "local-stack-bootstrap", "spicedb"] and
  .services.kratos.image == "docker.io/oryd/kratos:v26.2.0@sha256:2a13bb8d362c7a7ae33bd7c0f5168aee46921f15c916a06346db91c06dc76643" and
  .services["kratos-migrate"].image == .services.kratos.image and
  .services.spicedb.image == "docker.io/authzed/spicedb:v1.56.0@sha256:c8a558a6cc1f9379fcdcab0171b623d65e7e5f95c998ebb7f937ca00a7c1598c" and
  .services["local-stack-bootstrap"].image == "docker.io/curlimages/curl:8.21.0@sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13" and
  .services.kratos.depends_on["kratos-migrate"].condition == "service_completed_successfully" and
  .services["local-stack-bootstrap"].depends_on.kratos.condition == "service_healthy" and
  .services["local-stack-bootstrap"].depends_on.spicedb.condition == "service_started" and
  .services.kratos.read_only == true and
  .services["kratos-migrate"].read_only == true and
  .services.spicedb.read_only == true and
  .services["local-stack-bootstrap"].read_only == true and
  (.services.kratos.cap_drop == ["ALL"]) and
  (.services["kratos-migrate"].cap_drop == ["ALL"]) and
  (.services.spicedb.cap_drop == ["ALL"]) and
  (.services["local-stack-bootstrap"].cap_drop == ["ALL"]) and
  (.services["kratos-migrate"].tmpfs | sort) == ["/home/ory:uid=10000,gid=10000,mode=0700", "/tmp:mode=0700"] and
  (.services.kratos.tmpfs | sort) == ["/home/ory:uid=10000,gid=10000,mode=0700", "/tmp:mode=0700"] and
  (.services["local-stack-bootstrap"].volumes | length) == 2 and
  (.services["local-stack-bootstrap"].volumes | all(.type == "bind" and .read_only == true)) and
  (.services["local-stack-bootstrap"].volumes | map(.target) | sort) == ["/fixtures", "/smoke/smoke.sh"] and
  (.services.kratos.ports | length == 1 and .[0].target == 4433 and .[0].published == "4433" and .[0].host_ip == "127.0.0.1" and .[0].protocol == "tcp") and
  (.services.spicedb.ports | length == 1 and .[0].target == 50051 and .[0].published == "50051" and .[0].host_ip == "127.0.0.1" and .[0].protocol == "tcp") and
  (.services.kratos.ports | all(.target != 4434)) and
  (.services.spicedb.ports | all(.target != 8443 and .target != 9090 and .target != 50053)) and
  .services.kratos.environment.SPICEDB_GRPC_PRESHARED_KEY == "" and
  .services["kratos-migrate"].environment.SPICEDB_GRPC_PRESHARED_KEY == "" and
  .services.spicedb.environment.SECRETS_CIPHER == "" and
  .services.spicedb.environment.SECRETS_COOKIE == "" and
  .services.spicedb.environment.SECRETS_PAGINATION == "" and
  .services["local-stack-bootstrap"].environment.SECRETS_CIPHER == "" and
  .services["local-stack-bootstrap"].environment.SECRETS_COOKIE == "" and
  .services["local-stack-bootstrap"].environment.SECRETS_PAGINATION == "" and
  .networks["local-internal"].internal == true
' "$model" >/dev/null || fail 'tracked model violates the local topology or privilege contract'

if grep -Eq '^[[:space:]]+(methods|flows|allowed_return_urls):' "$tmp_dir/repo/config/upstream/kratos/local/kratos.yaml"; then
  fail 'Kratos local fixture configures out-of-scope self-service flow behavior'
fi

if grep -Eqi '(^|[^a-z])(latest|postgres|cockroach|mysql|hydra|oathkeeper|keto)([^a-z]|$)' "$model"; then
  fail 'tracked model contains a floating tag, production datastore, or excluded service'
fi

printf '%s\n' 'ok - Compose model is pinned, isolated, least-privilege, and secret-safe'
