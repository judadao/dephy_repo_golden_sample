# dephy_repo_golden_sample

Golden sample repository for Dephy product applications.

This repo shows the expected structure for a product that consumes reusable
modules through pinned dependencies and builds through a Dephy-managed Zephyr
workspace. It is intentionally small: the app skeleton boots, logs startup, and
keeps reusable logic in dependencies instead of copying module code into the
product tree.

## Layout

```text
dephy_repo_golden_sample/
├── deps.json
├── app/
│   ├── CMakeLists.txt
│   ├── prj.conf
│   └── src/main.c
├── scripts/
│   ├── sync_deps.sh
│   └── build_product.sh
├── tests/linux/
│   ├── Makefile
│   ├── test_repo_layout.sh
│   ├── test_sync_deps.sh
│   └── test_build_scripts.sh
└── docs/
    ├── product_structure.md
    └── validation.md
```

## Dependency Flow

Dependencies are declared in `deps.json`.

- `repo`: release/external source.
- `local`: sibling checkout used during local development.
- `version`: pinned tag or commit.
- `path`: materialized checkout under `deps/`.
- `module_path`: optional Zephyr module path if it differs from `path`.

Release-style flow:

```bash
./scripts/sync_deps.sh download
./scripts/sync_deps.sh init
./scripts/build_product.sh
```

Local development flow:

```bash
./scripts/sync_deps.sh replace
./scripts/build_product.sh --dry-run
```

`init` delegates Zephyr workspace setup to Dephy. Product builds consume source
and Zephyr module metadata from `deps/`, not from arbitrary sibling checkouts.
Product repositories should depend on module repositories only; do not list
other product repositories in `deps.json`.

## Tests

```bash
make -C tests/linux test
```

The integration scripts validate the product repo contract:

- required product layout exists;
- `repo.json` identifies the repo as a product template;
- dependency sync is idempotent and rejects dirty checkouts;
- `deps.json` lists module dependencies only;
- local `replace` creates non-git dependency copies;
- build scripts parse `deps.json` and produce expected Zephyr inputs.

## Customizing

Rename the product, update `deps.json` pins, add product-owned modules under
`app/src/`, and extend `tests/linux/` with product-specific host tests. Keep
reusable drivers, protocol adapters, and broker behavior in their module repos.
