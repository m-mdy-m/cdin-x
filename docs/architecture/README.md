# cdin-x architecture

## Boundary

CDIN is the editor/runtime. CDIN-X is the extension ecosystem and the runtime-side
manager API. They are intentionally separate repositories.

```text
CDIN
 ├─ C/Lua editor runtime
 ├─ data/core/                 core modules
 ├─ data/core/x/               CDIN-X runtime integration
 ├─ data/X/core/               mandatory built-in extensions
 └─ data/fonts/                immutable core assets

User state
 ├─ config/.../cdin/user/      personal configuration
 ├─ data/.../cdin/extensions/  installed optional extensions
 └─ data/.../cdin/registry/    cached cdin-x catalog

CDIN-X repository
 ├─ core/                      manager/loader/manifest runtime
 ├─ X/                         official extension sources
 ├─ fonts/                     bundled fonts
 ├─ registry/                  generated catalog data
 ├─ templates/                 scaffolds
 └─ docs/                      contracts and guides
```

## Runtime flow

```text
CDIN boot
  ↓
core.lifecycle
  ↓
core.x.bootstrap()
  ↓
scan built-ins + installed extensions
  ↓
resolve dependencies
  ↓
load init.lua modules
  ↓
load external user config
```

The registry is never part of the boot-critical path. CDIN can start with no network,
no registry clone and no optional extensions because built-ins live in the CDIN
installation itself.

## Source precedence

1. `data/X` — built-in; highest priority and immutable from the manager.
2. user extension store — installed and user-managed.
3. registry cache — catalog/source for extensions not yet installed.

## Lifecycle

`install -> enable -> load -> disable -> uninstall`.

An extension can be installed without being enabled. Built-ins are always enabled and
cannot be disabled or uninstalled.

## Dependency model

Each `manifest.lua` may declare `dependencies = { "other-extension" }`.
The manager resolves dependencies before loading and refuses cycles.

## UI boundary

The Vim `m` menu is only a gateway to the manager. UI code lives in
`core/command.lua`; installation/state logic stays in `core/manager.lua`.
