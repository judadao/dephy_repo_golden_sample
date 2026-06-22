# Product Structure

Use this repository as the starting point for Dephy product applications.

## Ownership Boundaries

- `app/`: product-owned Zephyr application code and configuration.
- `deps.json`: pinned dependency contract for reusable modules and Dephy board
  setup.
- `deps/`: generated dependency checkouts; do not commit.
- `scripts/`: product commands for dependency sync and product builds.
- `tests/linux/`: host-side validation of product repository behavior.
- `docs/`: product notes, validation procedures, and release guidance.

Reusable broker, protocol, board, and driver behavior should be implemented in
module repositories first, then consumed here through `deps.json`.

`repo.json` marks this repository as a `product_template`. Product repositories
should use `repo_type: product`; reusable dependency repositories should use
`repo_type: module`.

## Product Build Contract

Product builds should consume only dependency material under `deps/`. This keeps
release builds reproducible and prevents accidental coupling to sibling working
trees.

`scripts/sync_deps.sh replace` exists for local iteration. It copies sibling
checkouts into `deps/` without `.git`, build outputs, or local Zephyr workspaces.

Run `scripts/audit_product_structure.sh PRODUCT_REPO...` to check that product
repos keep the expected app, dependency, script, docs, and Linux test entry
points.
