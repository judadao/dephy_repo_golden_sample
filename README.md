# dephy_repo_golden_sample

Golden sample for Dephy product application repositories.

## Overview

This repo is the reference shape for product apps. Product repos compose pinned
modules, own product behavior, and avoid copying reusable logic into `app/src/`.

## Key Value

- Consistent product dependency flow.
- Clear split between product code and reusable modules.
- Structure audit for product repos.
- Local replace flow for sibling module development.

## How To Use

```sh
./scripts/sync_deps.sh download
./scripts/sync_deps.sh replace
./scripts/build_product.sh --dry-run
make -C tests/linux test
scripts/audit_product_structure.sh ../mqtt_field_bridge_app
```

## Simple Principle

Modules implement reusable behavior first. Products pin released module tags and
stay thin.

## Docs

- `docs/todo.md`: current TODO summary.
