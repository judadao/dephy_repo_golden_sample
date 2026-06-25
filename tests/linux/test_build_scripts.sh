#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

echo "=== test_build_scripts.sh ==="

board=$("$ROOT_DIR/scripts/sync_deps.sh" --board)
if [ "$board" = "esp32_devkitc/esp32/procpu" ]; then
    ok "sync_deps --board prints configured board"
else
    fail "sync_deps --board unexpected output: $board"
fi

deps=$("$ROOT_DIR/scripts/sync_deps.sh" --list | tr '\n' ' ')
for dep in dephy mqtt_min_broker modbus_zephyr_esp32 dephy_testkit; do
    case "$deps" in
        *"$dep"*) ok "sync_deps --list includes $dep" ;;
        *) fail "sync_deps --list missing $dep: $deps" ;;
    esac
done
case "$deps" in
    *dephy_iot*) fail "sync_deps --list should not include dephy_iot product repo" ;;
    *) ok "sync_deps --list excludes product repos" ;;
esac

broker_version=$("$ROOT_DIR/scripts/sync_deps.sh" --version mqtt_min_broker)
if [ -n "$broker_version" ]; then
    ok "sync_deps --version prints broker pin"
else
    fail "sync_deps --version returned empty broker pin"
fi

dry_run=$("$ROOT_DIR/scripts/build_product.sh" --dry-run 2>&1)
if printf '%s\n' "$dry_run" | grep -q 'board=esp32_devkitc/esp32/procpu'; then
    ok "build_product --dry-run prints board"
else
    fail "build_product --dry-run did not print board"
fi

if printf '%s\n' "$dry_run" | grep -q 'dephy_workspace=deps/dephy/zephyrproject'; then
    ok "build_product --dry-run prints Dephy workspace"
else
    fail "build_product --dry-run did not print Dephy workspace"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
