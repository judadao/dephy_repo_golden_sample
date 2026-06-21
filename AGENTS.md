# Repository Guidelines

## Project Structure

This repository is a golden sample for Dephy product applications. Product
firmware lives in `app/`, dependency pins live in `deps.json`, local dependency
checkouts are materialized under `deps/`, helper commands live in `scripts/`,
Linux validation lives in `tests/linux/`, and product notes live in `docs/`.

## Development Model

Keep reusable behavior in reusable module repositories first. Product code should
stay thin: pin modules in `deps.json`, sync them into `deps/`, include public
headers, and call module APIs from product-owned integration points.

External/release builds use dependency `repo` URLs and pinned `version` tags.
Local builds may use dependency `local` sibling paths and copy them into `deps/`
with `scripts/sync_deps.sh replace`.

## Commands

- `./scripts/sync_deps.sh download`: clone/fetch pinned dependencies.
- `./scripts/sync_deps.sh init`: initialize the Dephy-managed Zephyr workspace.
- `./scripts/build_product.sh`: run the Zephyr product build.
- `./scripts/build_product.sh --dry-run`: print the computed build inputs.
- `make -C tests/linux test`: run product repository integration checks.

## Style

Use C11, four-space indentation, snake_case symbols, and small product-owned
integration functions. Keep product-specific workflow code under `app/src/`.

## Testing

Run `make -C tests/linux test` after changing scripts, dependency layout, or
product app structure. Run `./scripts/build_product.sh --dry-run` before a full
Zephyr build when editing `deps.json`.

