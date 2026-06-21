# Validation

Run the repository-level integration checks:

```bash
make -C tests/linux test
```

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

