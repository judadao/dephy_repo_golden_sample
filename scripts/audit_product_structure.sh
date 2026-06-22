#!/bin/sh
set -eu

failures=0

usage() {
    echo "usage: $0 PRODUCT_REPO [PRODUCT_REPO ...]" >&2
}

check_path() {
    repo="$1"
    path="$2"
    if [ ! -e "$repo/$path" ]; then
        echo "$repo: missing $path" >&2
        failures=$((failures + 1))
    fi
}

check_repo_json() {
    repo="$1"
    type=$(python3 - "$repo/repo.json" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("repo_type", ""))
PY
)
    if [ "$type" != "product" ] && [ "$type" != "product_template" ]; then
        echo "$repo: repo_type must be product or product_template" >&2
        failures=$((failures + 1))
    fi
}

check_deps_json() {
    repo="$1"
    python3 - "$repo/deps.json" <<'PY'
import json
import sys
from pathlib import Path

deps = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("deps", {})
missing = [name for name, dep in deps.items() if "repo" not in dep or "path" not in dep or "version" not in dep]
if missing:
    print("deps missing repo/path/version: " + ", ".join(missing), file=sys.stderr)
    sys.exit(1)
PY
    rc=$?
    if [ "$rc" -ne 0 ]; then
        failures=$((failures + 1))
    fi
}

check_repo() {
    repo="$1"
    if [ ! -d "$repo" ]; then
        echo "$repo: not a directory" >&2
        failures=$((failures + 1))
        return
    fi

    check_path "$repo" repo.json
    check_path "$repo" deps.json
    check_path "$repo" AGENTS.md
    check_path "$repo" README.md
    check_path "$repo" app/CMakeLists.txt
    check_path "$repo" app/prj.conf
    check_path "$repo" scripts/sync_deps.sh
    check_path "$repo" scripts/build_product.sh
    check_path "$repo" docs/todo.yaml
    check_path "$repo" tests/linux/Makefile

    if [ -f "$repo/repo.json" ]; then
        check_repo_json "$repo"
    fi
    if [ -f "$repo/deps.json" ]; then
        check_deps_json "$repo"
    fi

    echo "$repo: checked"
}

if [ "$#" -eq 0 ]; then
    usage
    exit 2
fi

for repo in "$@"; do
    check_repo "$repo"
done

if [ "$failures" -ne 0 ]; then
    echo "product structure audit failed: $failures issue(s)" >&2
    exit 1
fi

echo "product structure audit passed"
