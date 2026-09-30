# cdin-x Documentation

## Overview

cdin-x is the extension ecosystem for
[cdin](https://github.com/m-mdy-m/cdin). It provides the mandatory set a cdin
build bundles, the optional user-facing workflows, the plugin manager, and the
catalog those plugins come from.

## Where to start

| you want to | read |
| --- | --- |
| install it | [`README.md`](../README.md) — `make install` / `make link` |
| write a plugin | [`X/README.md`](../X/README.md) — layout, manifest, lifecycle |
| wire two plugins together | [`X/integration/README.md`](../X/integration/README.md) |
| extend vim | [`X/core/vim/README.md`](../X/core/vim/README.md) — the registry |
| contribute | [`CONTRIBUTING.md`](../CONTRIBUTING.md) — the rules `make validate` enforces |
| know what cdin guarantees | cdin's [extension contract](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md) |

## Tasks

```sh
make validate     # the gate: structure, rules, and a real bundle run
make manifest     # regenerate X/manifest.lua
make list         # print the catalog
make bundle DEST=…  # what a cdin build consumes
```
