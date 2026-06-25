#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

expect_file() {
    if [ -f "$ROOT_DIR/$1" ]; then ok "file exists: $1"; else fail "missing file: $1"; fi
}

expect_dir() {
    if [ -d "$ROOT_DIR/$1" ]; then ok "dir exists: $1"; else fail "missing dir: $1"; fi
}

echo "=== test_repo_layout.sh ==="

expect_file deps.json
expect_dir app
expect_file app/CMakeLists.txt
expect_file app/prj.conf
expect_file app/src/main.c
expect_dir scripts
expect_file scripts/sync_deps.sh
expect_file scripts/build_product.sh
expect_dir docs
expect_dir tests/linux
expect_file tests/linux/Makefile
expect_file tests/linux/trigger_testkit.sh

if jq -e '.repo_type == "product_template"' "$ROOT_DIR/repo.json" >/dev/null; then
    ok "repo.json marks this repo as a product template"
else
    fail "repo.json should mark this repo as a product template"
fi

if jq -e '.deps.dephy and .deps.mqtt_min_broker and .deps.modbus_zephyr_esp32 and .deps.dephy_testkit and .build.board' "$ROOT_DIR/deps.json" >/dev/null; then
    ok "deps.json declares module deps and build.board"
else
    fail "deps.json missing required product dependency fields"
fi

if jq -e '.deps | has("dephy_iot") | not' "$ROOT_DIR/deps.json" >/dev/null; then
    ok "deps.json does not depend on product repos"
else
    fail "deps.json must not depend on dephy_iot product repo"
fi

if grep -q 'project(dephy_repo_golden_sample)' "$ROOT_DIR/app/CMakeLists.txt"; then
    ok "app CMake project name is present"
else
    fail "app CMake project name missing"
fi

if grep -q 'CONFIG_MQTT_P2P_DYNAMIC=y' "$ROOT_DIR/app/prj.conf"; then
    ok "sample keeps dynamic P2P enabled"
else
    fail "sample should keep dynamic P2P enabled"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
