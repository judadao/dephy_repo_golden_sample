# Validation

Run the repository-level integration checks:

```bash
make -C tests/linux test
```

The `test` target triggers the integration suite through `dephy_testkit` using
`tests/linux/trigger_testkit.sh`. Keep direct targets such as
`integration-tests` available for debugging, but route default and CI-style
runs through `testkit-*` wrappers. When changing a test case or shell script,
update both the direct Makefile target and the testkit wrapper.

Before a firmware build, verify the computed Zephyr inputs:

```bash
./scripts/build_product.sh --dry-run
```

For a release-style build:

```bash
./scripts/sync_deps.sh download
./scripts/sync_deps.sh init
./scripts/build_product.sh
```

The first `init` may download the Zephyr workspace, modules, Python packages,
and Espressif blobs. Later runs should reuse the Dephy-managed workspace unless
`DEPHY_FORCE_WEST_UPDATE=1` is set.
