#!/bin/sh

set -eu

phase=${1:-}
case "$phase" in
  spicedb-ready|prepare|verify|pollute|reset-verify) ;;
  *)
    printf '%s\n' 'local-stack smoke: expected spicedb-ready, prepare, verify, pollute, or reset-verify phase' >&2
    exit 64
    ;;
esac

fail() {
  printf 'local-stack smoke: %s\n' "$1" >&2
  exit 1
}

require_fixture() {
  if [ ! -f "$1" ] || [ -L "$1" ]; then
    fail "fixture is missing or unsafe: $1"
  fi
}

request_status() {
  response_file=$1
  shift
  curl --silent --show-error --output "$response_file" --write-out '%{http_code}' \
    --connect-timeout 2 --max-time 10 "$@"
}

expect_status() {
  expected_status=$1
  actual_status=$2
  stage=$3
  [ "$actual_status" = "$expected_status" ] ||
    fail "$stage failed at HTTP status gate (expected $expected_status, received $actual_status)"
}

expect_literal() {
  literal=$1
  response_file=$2
  stage=$3
  grep -Fq "$literal" "$response_file" || fail "$stage returned an incompatible response"
}

expect_occurrences() {
  expected_count=$1
  literal=$2
  response_file=$3
  stage=$4
  actual_count=$(grep -Fo "$literal" "$response_file" | wc -l | tr -d ' ')
  [ "$actual_count" = "$expected_count" ] ||
    fail "$stage returned $actual_count matches instead of $expected_count"
}

assert_not_exposed() {
  response_file=$1
  stage=$2
  for sensitive_value in \
    "$SPICEDB_GRPC_PRESHARED_KEY" \
    "${runtime_password:-}" \
    "${old_spicedb_key:-}" \
    "$invalid_session" \
    "$wrong_spicedb_key"; do
    if [ -n "$sensitive_value" ] && grep -Fq "$sensitive_value" "$response_file"; then
      fail "$stage response exposed test credential or session material"
    fi
  done
}

fixture_root=/fixtures
identity_fixture="$fixture_root/kratos/identity.json"
allow_fixture="$fixture_root/spicedb/check-allow.json"
deny_fixture="$fixture_root/spicedb/check-deny.json"
for fixture in "$identity_fixture" "$allow_fixture" "$deny_fixture"; do
  require_fixture "$fixture"
done

printf '%s\n' "$SPICEDB_GRPC_PRESHARED_KEY" | grep -Eq '^[A-Za-z0-9_-]{43}$' ||
  fail 'SpiceDB credential failed the local credential contract'

umask 077
temporary_dir=$(mktemp -d)
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM
auth_config="$temporary_dir/spicedb-auth.conf"
wrong_auth_config="$temporary_dir/spicedb-wrong-auth.conf"
printf 'header = "Authorization: Bearer %s"\n' "$SPICEDB_GRPC_PRESHARED_KEY" >"$auth_config"
wrong_spicedb_key=local-smoke-wrong-preshared-key
printf 'header = "Authorization: Bearer %s"\n' "$wrong_spicedb_key" >"$wrong_auth_config"
invalid_session=local-smoke-invalid-session-cookie
runtime_password=

if [ "$phase" = spicedb-ready ]; then
  readiness_response="$temporary_dir/spicedb-readiness.json"
  if ! readiness_status=$(request_status "$readiness_response" --config "$auth_config" \
    --request POST --header 'Content-Type: application/json' --data '{}' \
    http://spicedb:8443/v1/schema/read); then
    fail 'SpiceDB authenticated readiness request failed'
  fi
  case "$readiness_status" in
    200|404) ;;
    *) fail "SpiceDB authenticated readiness returned HTTP $readiness_status" ;;
  esac
  assert_not_exposed "$readiness_response" 'SpiceDB authenticated readiness'
  printf '%s\n' 'local component-fixture compatibility: pass'
  exit 0
fi

if [ "$phase" = pollute ]; then
  pollution_request="$temporary_dir/spicedb-pollution.json"
  cat >"$pollution_request" <<'JSON'
{"updates":[{"operation":"OPERATION_TOUCH","relationship":{"resource":{"objectType":"local_smoke_document","objectId":"fixture-document"},"relation":"viewer","subject":{"object":{"objectType":"local_smoke_user","objectId":"fixture-denied"}}}}]}
JSON
  pollution_response="$temporary_dir/spicedb-pollution-response.json"
  if ! pollution_status=$(request_status "$pollution_response" --config "$auth_config" \
    --request POST --header 'Content-Type: application/json' --data-binary "@$pollution_request" \
    http://spicedb:8443/v1/relationships/write); then
    fail 'SpiceDB undeclared-relationship setup failed'
  fi
  expect_status 200 "$pollution_status" 'SpiceDB undeclared-relationship setup'
  assert_not_exposed "$pollution_response" 'SpiceDB undeclared-relationship setup'
  printf '%s\n' 'local component-fixture compatibility: pass'
  exit 0
fi

schema_response="$temporary_dir/kratos-schema.json"
if ! schema_status=$(request_status "$schema_response" \
  http://kratos:4433/schemas/bG9jYWwtc21va2U); then
  fail 'Kratos identity-schema request failed'
fi
expect_status 200 "$schema_status" 'Kratos identity-schema lookup'
expect_literal '"title":"Local smoke identity"' "$schema_response" 'Kratos identity-schema lookup'
assert_not_exposed "$schema_response" 'Kratos identity-schema lookup'

lookup_response="$temporary_dir/kratos-identity-lookup.json"
lookup_identity() {
  if ! lookup_status=$(request_status "$lookup_response" --get \
    --data-urlencode 'credentials_identifier=local-smoke-u4@identity-stack.invalid' \
    http://kratos:4434/admin/identities); then
    fail 'Kratos identity lookup request failed'
  fi
  expect_status 200 "$lookup_status" 'Kratos identity lookup'
}

assert_one_identity() {
  expect_occurrences 1 '"schema_id":"local-smoke"' "$lookup_response" 'Kratos identity lookup'
  expect_literal '"identifiers":["local-smoke-u4@identity-stack.invalid"]' \
    "$lookup_response" 'Kratos identity lookup'
  expect_literal '"email":"local-smoke-u4@identity-stack.invalid"' \
    "$lookup_response" 'Kratos identity lookup'
  assert_not_exposed "$lookup_response" 'Kratos identity lookup'
}

lookup_identity
identity_count=$(grep -Fo '"schema_id":"local-smoke"' "$lookup_response" | wc -l | tr -d ' ')
if [ "$phase" = reset-verify ]; then
  [ "$identity_count" -eq 0 ] || fail 'Kratos retained the pre-reset fixture identity'
  IFS= read -r old_spicedb_key || fail 'old SpiceDB key was not supplied for reset evidence'
  printf '%s\n' "$old_spicedb_key" | grep -Eq '^[A-Za-z0-9_-]{43}$' ||
    fail 'old SpiceDB key failed the local credential contract'
  [ "$old_spicedb_key" != "$SPICEDB_GRPC_PRESHARED_KEY" ] || fail 'reset did not rotate the SpiceDB key'
  old_auth_config="$temporary_dir/spicedb-old-auth.conf"
  printf 'header = "Authorization: Bearer %s"\n' "$old_spicedb_key" >"$old_auth_config"
  old_key_response="$temporary_dir/spicedb-old-key.json"
  if ! old_key_status=$(request_status "$old_key_response" --config "$old_auth_config" \
    --request POST --header 'Content-Type: application/json' --data-binary "@$allow_fixture" \
    http://spicedb:8443/v1/permissions/check); then
    fail 'old SpiceDB key reset check failed'
  fi
  expect_status 403 "$old_key_status" 'old SpiceDB key rejection after reset'
  assert_not_exposed "$old_key_response" 'old SpiceDB key rejection after reset'
  printf '%s\n' 'local reset evidence: pass'
  exit 0
fi
case "$identity_count:$phase" in
  0:prepare)
    runtime_password=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
    printf '%s\n' "$runtime_password" | grep -Eq '^[0-9a-f]{48}$' ||
      fail 'runtime identity password generation failed'
    identity_request="$temporary_dir/kratos-identity-create.json"
    sed "s/LOCAL_SMOKE_RUNTIME_PASSWORD/$runtime_password/" "$identity_fixture" >"$identity_request"
    create_response="$temporary_dir/kratos-identity-create-response.json"
    if ! create_status=$(request_status "$create_response" --request POST \
      --header 'Content-Type: application/json' --data-binary "@$identity_request" \
      http://kratos:4434/admin/identities); then
      fail 'Kratos identity creation request failed'
    fi
    expect_status 201 "$create_status" 'Kratos identity creation'
    expect_literal '"schema_id":"local-smoke"' "$create_response" 'Kratos identity creation'
    assert_not_exposed "$create_response" 'Kratos identity creation'
    lookup_identity
    assert_one_identity
    ;;
  1:prepare|1:verify)
    assert_one_identity
    ;;
  0:verify)
    fail 'Kratos persisted identity was not found after restart'
    ;;
  *)
    fail "Kratos identity lookup returned an ambiguous fixture set ($identity_count matches)"
    ;;
esac

session_response="$temporary_dir/kratos-invalid-session.json"
if ! session_status=$(request_status "$session_response" \
  --header 'Accept: application/json' \
  --header "Cookie: ory_kratos_session=$invalid_session" \
  http://kratos:4433/sessions/whoami); then
  fail 'Kratos invalid-session request failed'
fi
expect_status 401 "$session_status" 'Kratos invalid-session rejection'
expect_literal '"code":401' "$session_response" 'Kratos invalid-session rejection'
expect_literal '"status":"Unauthorized"' "$session_response" 'Kratos invalid-session rejection'
assert_not_exposed "$session_response" 'Kratos invalid-session rejection'

schema_read_response="$temporary_dir/spicedb-schema-read.json"
if ! schema_read_status=$(request_status "$schema_read_response" --config "$auth_config" \
  --request POST --header 'Content-Type: application/json' --data '{}' \
  http://spicedb:8443/v1/schema/read); then
  fail 'SpiceDB schema reconciliation request failed'
fi
expect_status 200 "$schema_read_status" 'SpiceDB schema reconciliation'
expect_literal 'definition local_smoke_document' "$schema_read_response" 'SpiceDB schema reconciliation'
assert_not_exposed "$schema_read_response" 'SpiceDB schema reconciliation'

allow_response="$temporary_dir/spicedb-check-allow.json"
if ! allow_status=$(request_status "$allow_response" --config "$auth_config" \
  --request POST --header 'Content-Type: application/json' --data-binary "@$allow_fixture" \
  http://spicedb:8443/v1/permissions/check); then
  fail 'SpiceDB allow request failed'
fi
expect_status 200 "$allow_status" 'SpiceDB allow check'
expect_literal '"permissionship":"PERMISSIONSHIP_HAS_PERMISSION"' "$allow_response" 'SpiceDB allow check'
assert_not_exposed "$allow_response" 'SpiceDB allow check'

deny_response="$temporary_dir/spicedb-check-deny.json"
if ! deny_status=$(request_status "$deny_response" --config "$auth_config" \
  --request POST --header 'Content-Type: application/json' --data-binary "@$deny_fixture" \
  http://spicedb:8443/v1/permissions/check); then
  fail 'SpiceDB deny request failed'
fi
expect_status 200 "$deny_status" 'SpiceDB deny check'
expect_literal '"permissionship":"PERMISSIONSHIP_NO_PERMISSION"' "$deny_response" 'SpiceDB deny check'
assert_not_exposed "$deny_response" 'SpiceDB deny check'

omitted_key_response="$temporary_dir/spicedb-omitted-key.json"
if ! omitted_key_status=$(request_status "$omitted_key_response" \
  --request POST --header 'Content-Type: application/json' --data-binary "@$allow_fixture" \
  http://spicedb:8443/v1/permissions/check); then
  fail 'SpiceDB omitted-key request failed'
fi
expect_status 401 "$omitted_key_status" 'SpiceDB omitted-key rejection'
assert_not_exposed "$omitted_key_response" 'SpiceDB omitted-key rejection'

wrong_key_response="$temporary_dir/spicedb-wrong-key.json"
if ! wrong_key_status=$(request_status "$wrong_key_response" --config "$wrong_auth_config" \
  --request POST --header 'Content-Type: application/json' --data-binary "@$allow_fixture" \
  http://spicedb:8443/v1/permissions/check); then
  fail 'SpiceDB wrong-key request failed'
fi
expect_status 403 "$wrong_key_status" 'SpiceDB wrong-key rejection'
assert_not_exposed "$wrong_key_response" 'SpiceDB wrong-key rejection'

printf '%s\n' 'local component-fixture compatibility: pass'
