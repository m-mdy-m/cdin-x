# X/core

What has not moved into `packages/` yet. The move is one directory at a time and
it is nearly done: a package lives under `packages/<domain>/<name>` once it has a
`package.lua`, and stays here until then. Both roots are scanned, so a package is
found wherever it is and a tree can be half-moved.

**One entry is left:**

| entry | what it is |
| --- | --- |
| `vim` | vim mode — the largest package. Phase 5 merges the seven `vim-*` integrations into it as `with/` files, and they leave `../integration/` |

`manager` was here too, and `bundles/standard.lua` used to name it. What it
bootstrapped is `cdinx/`, and every bundle writes the kernel and its shim into the
build whether or not a bundle lists anything — so the panel is reachable without a
package being responsible for it. See `../../plugins/cdin-x/init.lua`.

## Dependencies

A plugin here may not depend on another plugin without declaring it, and must use a
dependency through its root module only — its submodules are private. If two of
these genuinely need each other, the wiring belongs in `../integration/`, which
declares the dependency so the manager can order the load.

That rule is about *packages*. Inside a package it does not apply: `workspace` has
four features and `window/keymap.lua` requires `window/commands.lua` freely,
because a feature's siblings are not a dependency, they are the same thing. The
line the rule draws is between two things a user can install separately.

The alternative is a plugin that works right up until somebody uninstalls the other
one, and a catalog nobody can reason about. `make validate` fails the build rather
than letting that happen.

## Nothing here is mandatory

There is no `essential` field and nothing that replaces it. What a build carries is
decided by a bundle in `../../bundles/`, and a build can ship none of this:
`make bundle BUNDLE=minimal` produces the kernel, its shim and the fonts, and
nothing else.

## Already in `packages/`

| was | is now | where |
| --- | --- | --- |
| `git` | `git` | `packages/vcs/git` |
| `treeview` | `treeview` | `packages/navigation/treeview` |
| `menu` | `menu` | `packages/navigation/menu` |
| `search` | `search` | `packages/navigation/search` |
| `autocomplete` | **`complete`** | `packages/editing/complete` |
| `autoupdate` | **`update`** | `packages/system/update` |
| `autoreload` + `trimwhitespace` | **`basics`** | `packages/editing/basics`, two features |
| `rtl_toggle` + `unicode_inspect` | **`text-tools`** | `packages/system/text-tools`, two features |
| `theme_switcher` + the ten themes | **`themes`** | `packages/system/themes`, one feature and ten theme files |
| `palette` + `finder` + `modules` | **`launcher`** | `packages/navigation/launcher`, three features |
| `tab` + `window` + `session` + `tab-session` | **`workspace`** | `packages/navigation/workspace`, four features |

Each of these carries a `package.lua`, so its identity is its name and its modules
are required as `require "git.api"` rather than by where it sits.

`autocomplete` and `autoupdate` were **renamed**, not just moved. Their command names
and their config keys were not: `autocomplete:complete`, `autocomplete:next` and
`autoupdate:check` are still spelled the old way, because a user's `init.lua` and a
keymap both name them. The same holds for `palette`, `finder`, `modules`, `tab`,
`window` and `session`: the package names moved, and not one command name or
keystroke did.

`basics`, `text-tools`, `themes`, `launcher` and `workspace` are built from
features: each member is a `features/<key>.lua` with an `enable()` and a
`disable()`, and each can be switched off on its own.

Two of these are not just co-located, they were *related* and are now one thing.

- `themes` absorbed `session/theme-switcher`, which existed only to push the
  switcher's choice into the session's saved theme. That is `themes`' own business
  now, declared as its `with/themes.lua` entry rather than as a dependency
  between two packages that must both be installed for either to work.
- `workspace` absorbed `tab-session`, an *integration* that needed both the tab
  manager and the session's quit hook. As features that ordering is just the order
  they are enabled in — `session` before `tab-session`, because `tab-session`
  subscribes to `session.on_quit()`. The dependency it used to declare became a
  position in a list, which is the whole reason the merge was worth doing.

`themes` is the awkward one. The host's theme root is `EXEDIR/data/themes`, that
path is in cdin's extension contract, and there is no way to ask the host to look
anywhere else — so the ten themes have to arrive at `<data>/themes/<name>/` in a
build. `scripts/bundle.py` flattens them there *and* leaves the package's own copy
in place, because a site install needs the second: the package registers its own
root with `themes.add_root`, and only the host is allowed to do that in a build.
Neither copy is generated or symlinked; both are the same files.

Details: [docs/writing-a-plugin.md](../../docs/writing-a-plugin.md).