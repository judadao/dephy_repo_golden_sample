#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DEPS_JSON="$ROOT_DIR/deps.json"
DRY_RUN=0

if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
fi

if command -v jq >/dev/null 2>&1; then
    BOARD=$(jq -r '.build.board // empty' "$DEPS_JSON")
    EXTRA_MODULES=$(jq -r '.deps | to_entries | map(.value.module_path // .value.path) | join(";")' "$DEPS_JSON")
    DEPHY_PATH=$(jq -r '.deps.dephy.path // empty' "$DEPS_JSON")
    DEPHY_WORKSPACE=$(jq -r '.build.dephy_workspace // empty' "$DEPS_JSON")
else
    BOARD=$(sed -n 's/.*"board": *"\([^"]*\)".*/\1/p' "$DEPS_JSON" | head -n 1)
    EXTRA_MODULES=$(sed -n 's/.*"path": *"\([^"]*\)".*/\1/p' "$DEPS_JSON" | paste -sd ';' -)
    DEPHY_PATH=$(sed -n '/"dephy"/,/"}/s/.*"path": *"\([^"]*\)".*/\1/p' "$DEPS_JSON" | head -n 1)
    DEPHY_WORKSPACE=deps/dephy/zephyrproject
fi

if [ -z "$BOARD" ]; then
    BOARD=esp32_devkitc/esp32/procpu
fi

if [ -z "$EXTRA_MODULES" ]; then
    printf 'error: failed to parse dependency module paths from deps.json\n' >&2
    exit 1
fi

EXTRA_MODULES_ABS=""
OLD_IFS=$IFS
IFS=';'
for module_path in $EXTRA_MODULES; do
    module_abs="$ROOT_DIR/$module_path"
    if [ ! -f "$module_abs/zephyr/module.yml" ]; then
        if [ "$DRY_RUN" = "1" ]; then
            printf 'dry-run: unresolved Zephyr module path: %s\n' "$module_path" >&2
        else
            printf 'skip non-Zephyr dependency module path: %s\n' "$module_path" >&2
        fi
        continue
    fi

    if [ -z "$EXTRA_MODULES_ABS" ]; then
        EXTRA_MODULES_ABS="$module_abs"
    else
        EXTRA_MODULES_ABS="$EXTRA_MODULES_ABS;$module_abs"
    fi
done
IFS=$OLD_IFS

if [ "$DRY_RUN" = "1" ]; then
    printf 'board=%s\n' "$BOARD"
    printf 'dephy_workspace=%s\n' "$DEPHY_WORKSPACE"
    printf 'extra_modules=%s\n' "$EXTRA_MODULES_ABS"
    exit 0
fi

if [ -n "$DEPHY_WORKSPACE" ] && [ -x "$ROOT_DIR/$DEPHY_WORKSPACE/.venv/bin/west" ]; then
    WEST="$ROOT_DIR/$DEPHY_WORKSPACE/.venv/bin/west"
    WEST_WORKDIR="$ROOT_DIR/$DEPHY_WORKSPACE"
elif command -v west >/dev/null 2>&1; then
    WEST=$(command -v west)
    WEST_WORKDIR=$ROOT_DIR
elif [ -n "$DEPHY_PATH" ] && [ -x "$ROOT_DIR/$DEPHY_PATH/zephyrproject/.venv/bin/west" ]; then
    WEST="$ROOT_DIR/$DEPHY_PATH/zephyrproject/.venv/bin/west"
    WEST_WORKDIR="$ROOT_DIR/$DEPHY_PATH/zephyrproject"
else
    printf 'error: west not found; run scripts/sync_deps.sh init first\n' >&2
    exit 1
fi

if [ -z "${ZEPHYR_SDK_INSTALL_DIR:-}" ] && [ -f "$WEST_WORKDIR/zephyr/SDK_VERSION" ]; then
    SDK_VERSION=$(cat "$WEST_WORKDIR/zephyr/SDK_VERSION")
    SDK_DIR="$HOME/zephyr-sdk-$SDK_VERSION"
    if [ -f "$SDK_DIR/cmake/Zephyr-sdkConfig.cmake" ]; then
        export ZEPHYR_SDK_INSTALL_DIR="$SDK_DIR"
    fi
fi

if [ -d "$WEST_WORKDIR/.venv/bin" ]; then
    PATH="$WEST_WORKDIR/.venv/bin:$PATH"
    export PATH
fi

(cd "$WEST_WORKDIR" && "$WEST" build -b "$BOARD" "$ROOT_DIR/app" \
    -- -DZEPHYR_EXTRA_MODULES="$EXTRA_MODULES_ABS")

