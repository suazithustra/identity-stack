#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd -P)
credentials="$ROOT_DIR/deploy/local/.local-stack-credentials.env"
state="$ROOT_DIR/deploy/local/.local-stack-state.json"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

read_key() {
  awk -F= '$1 == "SPICEDB_GRPC_PRESHARED_KEY" { count += 1; value = substr($0, length($1) + 2) } END { if (count != 1) exit 1; print value }' "$1"
}

[ -f "$credentials" ] && [ ! -L "$credentials" ] || fail 'pre-reset credentials are missing or unsafe'
old_key=$(read_key "$credentials") || fail 'pre-reset SpiceDB key is missing or duplicated'

"$ROOT_DIR/bin/local-stack" reset --yes
"$ROOT_DIR/bin/local-stack" init
"$ROOT_DIR/bin/local-stack" up

new_key=$(read_key "$credentials") || fail 'post-reset SpiceDB key is missing or duplicated'
[ "$old_key" != "$new_key" ] || fail 'reset retained the old SpiceDB key'

checkout_id=$(jq -er '.checkout_id' "$state") || fail 'post-reset checkout identity is missing'
config_identity=$(jq -er '.config_identity' "$state") || fail 'post-reset configuration identity is missing'
generation=$(jq -er '.state_generation' "$state") || fail 'post-reset generation is missing'
project=$(jq -er '.compose_project' "$state") || fail 'post-reset Compose project is missing'
output_file=$(mktemp "${TMPDIR:-/tmp}/identity-stack-reset-evidence.XXXXXX")
trap 'rm -f "$output_file"' EXIT HUP INT TERM

if ! printf '%s\n' "$old_key" | \
  LOCAL_STACK_CHECKOUT_ID="$checkout_id" \
  LOCAL_STACK_CONFIG_IDENTITY="$config_identity" \
  LOCAL_STACK_STATE_GENERATION="$generation" \
  docker compose --project-name "$project" --file "$ROOT_DIR/deploy/local/compose.yaml" \
    run --rm --no-deps --pull never --entrypoint /bin/sh \
    local-stack-bootstrap /smoke/smoke.sh reset-verify >"$output_file" 2>&1; then
  for sensitive_value in "$old_key" "$new_key"; do
    grep -Fq "$sensitive_value" "$output_file" && fail 'post-reset failure exposed credential material'
  done
  sed -n '1,20p' "$output_file" >&2
  fail 'post-reset component evidence failed'
fi

grep -Fqx 'local reset evidence: pass' "$output_file" || fail 'post-reset evidence returned an ambiguous result'
for sensitive_value in "$old_key" "$new_key"; do
  grep -Fq "$sensitive_value" "$output_file" && fail 'post-reset evidence exposed credential material'
done

"$ROOT_DIR/bin/local-stack" smoke
printf '%s\n' 'ok - reset rotates credentials and removes prior identity state'
