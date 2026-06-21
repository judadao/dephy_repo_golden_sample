#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT_DIR/scripts/sync_deps.sh"
BROKER_PATH="$ROOT_DIR/deps/mqtt_min_broker"
MODBUS_PATH="$ROOT_DIR/deps/modbus_zephyr_esp32"
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

check() {
    label=$1
    shift
    if "$@" >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi
}

check_fail() {
    label=$1
    shift
    if "$@" >/dev/null 2>&1; then fail "$label (expected failure)"; else ok "$label"; fi
}

check_output() {
    label=$1
    expected=$2
    shift 2
    actual=$("$@" 2>&1) || true
    if printf '%s' "$actual" | grep -qF "$expected"; then
        ok "$label"
    else
        fail "$label (got: $actual)"
    fi
}

echo "=== test_sync_deps.sh ==="

PINNED_BROKER=$(sh "$SCRIPT" --version mqtt_min_broker)

check "T1: download exits 0" sh "$SCRIPT" download
check "T2: second download exits 0" sh "$SCRIPT" download

if [ -f "$MODBUS_PATH/repo.json" ] &&
   jq -e '.repo_type == "module"' "$MODBUS_PATH/repo.json" >/dev/null; then
    ok "T2b: modbus dependency is marked as module"
else
    fail "T2b: modbus dependency should be marked as module"
fi

actual_version=$(git -C "$BROKER_PATH" describe --tags --exact-match 2>/dev/null || git -C "$BROKER_PATH" rev-parse --short HEAD)
if [ "$actual_version" = "$PINNED_BROKER" ]; then
    ok "T3: broker checkout matches pinned version"
else
    fail "T3: broker checkout mismatch (checked out=$actual_version pinned=$PINNED_BROKER)"
fi

touch "$BROKER_PATH/DIRTY_SYNC_TEST"
check_output "T4: dirty dependency prints error" "local modifications" sh "$SCRIPT" download
check_fail "T4: dirty dependency exits non-zero" sh "$SCRIPT" download
rm "$BROKER_PATH/DIRTY_SYNC_TEST"

check "T5: download succeeds after dirty cleanup" sh "$SCRIPT" download

check "T6: replace copies local sibling dependencies" sh "$SCRIPT" replace
if [ -f "$BROKER_PATH/zephyr/module.yml" ] && [ ! -d "$BROKER_PATH/.git" ]; then
    ok "T6: replace creates non-git dependency copy"
else
    fail "T6: replace did not create expected non-git copy"
fi

check "T7: download restores git dependency checkout" sh "$SCRIPT" download
if [ -d "$BROKER_PATH/.git" ]; then
    ok "T7: restored dependency is a git checkout"
else
    fail "T7: restored dependency is not a git checkout"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
