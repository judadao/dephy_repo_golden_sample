# dephy_repo_golden_sample

Golden sample for Dephy product application repositories.

This repo defines the expected shape of a product repo. A product owns
application behavior, provisioning, product tests, and dependency pins. Reusable
broker, protocol, IO, board, and driver behavior should be implemented in
module repos first, released there, then pinned by the product.

## Why This Exists

- Product repos need a consistent dependency flow.
- Reusable logic should not be copied into product `app/src/`.
- CI and local development should run the same sync/build/test commands.
- Refactors need an audit target to decide whether a product repo is drifting.

## Normal Flow

1. Product pins reusable modules in `deps.json`.
2. `scripts/sync_deps.sh download` fetches remote dependencies.
3. `scripts/sync_deps.sh replace` can swap in local sibling repos for active
   development.
4. `scripts/build_product.sh` builds the Zephyr app with synced dependencies.
5. Product Linux tests validate config, integration behavior, and dependency
   sync assumptions.

## How It Works

The product repo is intentionally thin. It composes modules, owns product
configuration, and contains integration tests that prove the whole product flow
works. Module implementation remains in module repos, so a fix to broker, IO,
or board behavior can be released once and consumed by multiple products.

## Contract

```text
repo.json                 repo_type: product or product_template
deps.json                 pinned reusable module dependencies
AGENTS.md
README.md
app/CMakeLists.txt
app/prj.conf
app/src/
scripts/sync_deps.sh
scripts/build_product.sh
docs/todo.yaml
tests/linux/Makefile
```

## Commands

```sh
make -C tests/linux test
scripts/audit_product_structure.sh ../mqtt_field_bridge_app
./scripts/sync_deps.sh download
./scripts/sync_deps.sh replace
./scripts/build_product.sh --dry-run
```

## TODO

TODO state is tracked in `docs/todo.yaml` and summarized in `docs/todo.md`.
