# dephy_repo_golden_sample

Golden sample for Dephy product application repositories.

Product repos own app behavior, provisioning, product tests, and dependency
pins. Reusable broker, protocol, IO, board, and driver behavior should be
implemented in module repos first, released there, then pinned here through
`deps.json`.

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
```

The Linux tests validate layout, dependency sync, local replace, build script
parsing, and the product structure audit.

## Dependency Flow

```sh
./scripts/sync_deps.sh download
./scripts/sync_deps.sh init
./scripts/build_product.sh
```

For local development:

```sh
./scripts/sync_deps.sh replace
./scripts/build_product.sh --dry-run
```

## TODO

TODO state is tracked in `docs/todo.yaml` and summarized in `docs/todo.md`.
