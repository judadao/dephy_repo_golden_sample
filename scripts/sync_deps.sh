#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DEPS_JSON="$ROOT_DIR/deps.json"

usage() {
    cat <<'EOF'
usage: scripts/sync_deps.sh [command]

commands:
  download        clone/fetch deps from deps.json into deps/ (default)
  init            update board Zephyr modules through Dephy
  replace         copy sibling/local module checkouts into deps/
  build           run scripts/build_product.sh
  local-build     replace, then build
  external-build  download, init, then build

inspection flags:
  --list          list dependency names
  --board         print the configured Zephyr board
  --version NAME  print the pinned version for a dependency
  --latest NAME   print the latest matching release tag for a dependency
EOF
}

require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        printf 'error: jq is required for dependency sync\n' >&2
        exit 1
    fi
}

resolve_path_or_url() {
    value=$1
    case "$value" in
        /*|git@*|http://*|https://*)
            printf '%s\n' "$value" ;;
        *)
            realpath -m "$ROOT_DIR/$value" ;;
    esac
}

dep_names() {
    require_jq
    jq -r '.deps | keys[]' "$DEPS_JSON"
}

dep_field() {
    require_jq
    name=$1
    field=$2
    jq -r --arg name "$name" --arg field "$field" '.deps[$name][$field] // empty' "$DEPS_JSON"
}

build_board() {
    require_jq
    board=$(jq -r '.build.board // empty' "$DEPS_JSON")
    if [ -z "$board" ]; then
        board=esp32_devkitc/esp32/procpu
    fi
    printf '%s\n' "$board"
}

dep_tag_pattern() {
    name=$1
    pattern=$(dep_field "$name" "tag_pattern")
    if [ -n "$pattern" ]; then
        printf '%s\n' "$pattern"
        return
    fi
    printf '%s\n' "*"
}

latest_dep_tag() {
    name=$1
    repo=$(dep_field "$name" "repo")
    pattern=$(dep_tag_pattern "$name")
    repo_abs=$(resolve_path_or_url "$repo")
    git ls-remote --tags "$repo_abs" "refs/tags/$pattern" 2>/dev/null \
        | sed 's#.*refs/tags/##; s/\^{}//' \
        | sort -u \
        | sort -V \
        | tail -n 1
}

sync_one_dep() {
    name=$1
    repo=$(dep_field "$name" "repo")
    local_repo=$(dep_field "$name" "local")
    version=$(dep_field "$name" "version")
    path=$(dep_field "$name" "path")

    if [ -z "$repo" ] || [ -z "$version" ] || [ -z "$path" ]; then
        printf 'error: failed to parse deps.json for %s\n' "$name" >&2
        exit 1
    fi

    repo_abs=$(resolve_path_or_url "$repo")
    clone_src="$repo_abs"
    if [ -n "$local_repo" ]; then
        local_abs=$(resolve_path_or_url "$local_repo")
        if [ -d "$local_abs/.git" ]; then
            clone_src="$local_abs"
        fi
    fi
    target="$ROOT_DIR/$path"

    mkdir -p "$ROOT_DIR/deps"

    if [ -e "$target" ] && [ ! -d "$target/.git" ]; then
        rm -rf "$target"
    fi

    if [ ! -d "$target/.git" ]; then
        git clone "$clone_src" "$target"
    fi

    if [ -n "$(git -C "$target" status --porcelain)" ]; then
        printf 'error: %s has local modifications\n' "$path" >&2
        printf '  Commit, stash, or discard changes before syncing.\n' >&2
        exit 1
    fi

    git -C "$target" fetch --tags --force
    if ! git -C "$target" rev-parse -q --verify "$version^{commit}" >/dev/null; then
        printf 'error: version %s not found in %s\n' "$version" "$target" >&2
        printf '  Create/fetch the tag or commit before syncing.\n' >&2
        exit 1
    fi
    git -C "$target" checkout -q "$version"

    printf '%s synced to %s\n' "$name" "$version"
}

download_deps() {
    for name in $(dep_names); do
        sync_one_dep "$name"
    done
}

copy_local_dep() {
    name=$1
    path=$(dep_field "$name" "path")
    local_repo=$(dep_field "$name" "local")

    if [ -z "$path" ]; then
        printf 'error: failed to parse deps.json path for %s\n' "$name" >&2
        exit 1
    fi

    if [ -z "$local_repo" ]; then
        local_repo="../$name"
    fi

    src=$(resolve_path_or_url "$local_repo")
    dst="$ROOT_DIR/$path"

    if [ ! -d "$src" ]; then
        printf 'error: local module %s not found at %s\n' "$name" "$src" >&2
        exit 1
    fi

    case "$dst" in
        "$ROOT_DIR"/deps/*) ;;
        *)
            printf 'error: refusing to replace non-deps path %s\n' "$path" >&2
            exit 1 ;;
    esac

    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"

    if command -v rsync >/dev/null 2>&1; then
        mkdir -p "$dst"
        rsync -a --delete \
            --exclude '.git/' \
            --exclude 'build/' \
            --exclude 'build_out/' \
            --exclude 'out/' \
            --exclude 'zephyrproject/' \
            "$src"/ "$dst"/
    else
        rm -rf "$dst"
        mkdir -p "$dst"
        (cd "$src" && tar --exclude .git --exclude build --exclude build_out --exclude out --exclude zephyrproject -cf - .) \
            | (cd "$dst" && tar -xf -)
    fi

    printf '%s replaced from %s\n' "$name" "$src"
}

replace_deps() {
    for name in $(dep_names); do
        copy_local_dep "$name"
    done
}

init_zephyr() {
    dephy_path=$(dep_field "dephy" "path")
    profile=$(dep_field "dephy" "profile")
    if [ -z "$dephy_path" ]; then
        printf 'error: deps.json must include a dephy dependency for init\n' >&2
        exit 1
    fi
    if [ -z "$profile" ]; then
        profile=esp32
    fi

    dephy_script="$ROOT_DIR/$dephy_path/boards/$profile/scripts/sync_zephyr_modules.sh"
    if [ ! -x "$dephy_script" ]; then
        printf 'error: Dephy board sync script not found: %s\n' "$dephy_script" >&2
        printf '  Run scripts/sync_deps.sh download or replace first.\n' >&2
        exit 1
    fi

    "$dephy_script"
}

case "${1:-download}" in
    --help|-h)
        usage ;;
    --list)
        dep_names ;;
    --board)
        build_board ;;
    --version)
        if [ -z "${2:-}" ]; then
            printf 'error: --version requires a dependency name\n' >&2
            exit 1
        fi
        dep_field "$2" "version" ;;
    --latest)
        if [ -z "${2:-}" ]; then
            printf 'error: --latest requires a dependency name\n' >&2
            exit 1
        fi
        latest=$(latest_dep_tag "$2")
        if [ -z "$latest" ]; then
            printf 'error: no matching tags found for %s\n' "$2" >&2
            exit 1
        fi
        printf '%s\n' "$latest" ;;
    download|sync)
        download_deps ;;
    init)
        init_zephyr ;;
    replace)
        replace_deps ;;
    build)
        "$ROOT_DIR/scripts/build_product.sh" ;;
    local-build)
        replace_deps
        "$ROOT_DIR/scripts/build_product.sh" ;;
    external-build)
        download_deps
        init_zephyr
        "$ROOT_DIR/scripts/build_product.sh" ;;
    *)
        usage >&2
        exit 1 ;;
esac

