# Changelog

All notable changes to this project are documented here. This file is
maintained automatically by [release-please](https://github.com/googleapis/release-please)
from [Conventional Commits](https://www.conventionalcommits.org/). Do not edit
released sections by hand.

## [1.3.0](https://github.com/xav-ie/nuenv/compare/v1.2.0...v1.3.0) (2026-07-07)


### Features

* **writeShellApplication:** highlighted ide-check diagnostics + nu-check linter ([30aa83e](https://github.com/xav-ie/nuenv/commit/30aa83ea716a0df3f88323285e8904d31578ba8f))


### Miscellaneous

* **release:** set up release-please and CHANGELOG ([4eb68ef](https://github.com/xav-ie/nuenv/commit/4eb68ef40006e1276daa5239a7a205b2fd65fe55))

## [1.2.0](https://github.com/xav-ie/nuenv/compare/v1.1.2...v1.2.0) (2026-07-06)

### Features

* update the bundled Nushell to 0.114.0 (via a package override, since nixpkgs was still on 0.113.1)

### Miscellaneous

* set up the FlakeHub dev shell cache so CI no longer recompiles Nushell from scratch

## [1.1.2](https://github.com/xav-ie/nuenv/compare/v1.1.1...v1.1.2) (2025-07-16)

### Features

* use standard systems via `nix-systems/default`

### Bug Fixes

* remove `rust-overlay` from inputs

## [1.1.1](https://github.com/xav-ie/nuenv/compare/v1.1.0...v1.1.1) (2025-07-16)

### Features

* set up flake `checks`

### Bug Fixes

* remove broken workflow code

## [1.1.0](https://github.com/xav-ie/nuenv/compare/v1.0.0...v1.1.0) (2025-07-16)

### Features

* `writeShellApplication`: allow specifying which Nushell package and arguments to use

## [1.0.0](https://github.com/xav-ie/nuenv/compare/v0.1.5...v1.0.0) (2025-07-16)

### Features

* add `nuenv.mkShell` (`mkNushellShell`)
* implement `nuenv.writeShellApplication`
* update the builder to Nushell 0.87.1

### Bug Fixes

* loosen overly restrictive types
* add parens in `user-env`
* ignore `.direnv` in `.gitignore`
* disable x-large and outdated macOS CI runners

### Miscellaneous

* add MIT license
* apply formatting and re-wording across the repo
* cache dev shell in FlakeHub Cache and use FlakeHub URLs for Nixpkgs
* add FlakeHub badge and fix README links

---

Releases prior to `v1.0.0` (`v0.1.0`–`v0.1.5`, 2023) predate this changelog;
see the git tags for their history.
