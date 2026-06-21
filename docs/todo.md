# Product Golden Sample TODO

Tracks work for the product repository template.

## Repo Identity

- [x] Add `repo.json` so the template is machine-recognizable as
      `repo_type: product_template`.
- [x] Document that product repositories may depend on module repositories only.

## Dependency Model

- [x] Remove product repositories from `deps.json`.
- [x] Keep sample dependencies limited to reusable modules: Dephy board support,
      MQTT broker, and Modbus adapter.
- [x] Add integration coverage that fails if `dephy_iot` or another product repo
      is added as a dependency.

## Validation

- [x] Keep Linux integration checks for repo layout, build-script parsing, and
      dependency sync behavior.
- [x] Run `make -C tests/linux test` after dependency model changes.
