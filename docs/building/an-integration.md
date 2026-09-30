# Building an integration

An integration connects two plugins that must not know about each other.

It is the thinnest kind of plugin there is — most are one file — and it is the
one place where the catalog's central rule actually applies. So this page is
short on mechanics and long on the two decisions you have to get right: which
relationships deserve an integration, and what you put in `dependencies`.

## When you need one

You need an integration when this is true:

> plugin A has something plugin B needs, and a direct dependency between them
> would be wrong.

That last clause is doing the work. Sometimes A genuinely cannot work without B,
and then the honest answer is that A and B are one plugin. Reach for an
integration when the coupling is *about use*, not about existence.

**A real one.** `search` can find text. `vim` can run a normal-mode key. Neither
depends on the other — a search is useful without vim, and vim is useful without
a search plugin. But <kbd>/</kbd> and <kbd>n</kbd> are what a vim user expects,
and they only make sense if someone maps them onto search. `vim-search` is that
mapping, and it is one file.

**Not a real one.** `treeview` cannot show a file list without reading the
filesystem. That is a dependency on the *runtime*, not on a plugin, and it
belongs in `treeview`. An integration there would be a file that forwards to
another file, which is worse than no file.

**Also not a real one.** Two commands in your own plugin that both use a shared
helper. That is a third module inside your plugin, not a new directory.

## The shape

```text
X/integration/<name>/
  init.lua        the manifest, and nothing else at the top level
  commands.lua    optional — cdin commands
  keymap.lua      optional — cdin keys
  *.lua           whatever the wiring needs
```

Most are one file. `vim-git` is three, because it has a menu section as well as
commands, and a menu section reads better on its own than inline in wiring.

## A complete one

Here is a working integration, start to finish. It makes the project's file
finder reachable from vim mode — the same shape as `vim-search`, and small
enough to hold in your head.

### 1. The manifest

```lua
-- X/integration/vim/vim-finder/init.lua
local M = {
  name         = "vim-finder",
  version      = "0.1.0",
  description  = "Reaches the file finder from vim mode",
  author       = "you",
  license      = "MIT",
  category     = "integration",
  type         = "plugin",
  essential    = false,
  dependencies = { "vim", "finder" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "finder" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.vim.vim-finder.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-finder.keymap").unregister()
  loaded = false
end

return M
```

Three things in that file deserve attention.

**`dependencies = { "vim", "finder" }`.** Both, and both named. The manager
sorts the load order on this list, so `vim` has its registry open and `finder`
has its commands registered before your keymap runs. Without it you are relying
on a `pairs()` walk happening to come out right, which it will, eventually, on
someone else's machine.

**Nothing is required at the top.** The catalog `dofile()`s this file to read
the manifest. A top-level `require` would load your whole subtree — and start
`vim` — for a plugin that may never be installed.

**`init(core, config)` or `init()`.** Both are called positionally as
`mod.init(core, config)`. `function M.init(config)` compiles and then reads the
core table as your config, and you will not find that by reading the signature.

### 2. The keys

```lua
-- X/integration/vim/vim-finder/keymap.lua
local registry = require "X.core.vim.registry"

local M = {}

local KEYS = {
  f = function()
    return require("core.input.command").perform("core:find-file")
  end,
}

function M.register()
  registry.register_key(KEYS)
end

function M.unregister()
  registry.unregister_key(KEYS)
end

return M
```

**`unregister_key(KEYS)` with the same table.** The registry matches by
identity, so a rebuilt table removes nothing. This is the single most common
mistake in an integration, and the symptom is a key that keeps working after you
uninstalled the plugin that owned it.

**Reaching the other plugin by command name, not by require.** Notice there is
no `require "X.core.finder"` anywhere. `command.perform("core:find-file")` is
the whole coupling, and it is why `dependencies` is enough — you do not need to
hold a reference to a module you did not load, and you cannot accidentally reach
into a plugin's internals.

### 3. Check it

```sh
make validate
```

It will tell you if you `require` something across a plugin boundary without a
declaration behind it, if your `register` has no matching `unregister`, or if
you touched something you should not have.

### 4. Run it

```sh
lua scripts/new-plugin.lua vim-finder integration
```

…gives you a stub. Or just create the directory — the scanner finds a plugin by
its `init.lua`, not by a registry entry. Then **Install Local** in the manager
and press <kbd>f</kbd>.

## The second worked example: extending a menu

This is the case that bites, so it gets its own section.

`menu` is a `core/` plugin. `vim-menu` is an `integration/` that defines the
menu called `vim.main`. Your integration wants to add a section to it.

```lua
dependencies = { "vim", "menu", "vim-menu" }
```

**All three.** `menu` is the capability that knows how to define and open a
menu. `vim-menu` is what actually defines `vim.main`. You need both, and the
third is the one everybody forgets.

```lua
menu.extend("vim.main", "my-section", function(context)
  return {
    header  = "Mine",
    entries = { { key = "z", label = "Zap", info = "the thing", action = zap } },
  }
end, 50)
```

```lua
menu.remove_extension("vim.main", "my-section")
```

The section's `id` is the second argument, and **that is what you unregister
with** — not the header string. Two sections may both be headed "Files"; the
header is for reading and the id is for addressing.

### Why forgetting `vim-menu` is so bad

`menu.extend` asserts the menu exists. The catalog is scanned with `pairs()`, so
the order plugins load in is **not stable between runs**. Declare `{ "vim",
"menu" }` and extend `vim.main`, and what you get is:

```
menu is not defined: vim.main
```

…on some runs and not others, depending on what order Lua happened to walk the
table. It is the worst shape a load-order bug can have: it works on your
machine, it works in CI, and it fails for the one person who reports it with no
other detail. The `vim-menu` entry in `dependencies` is what makes it
impossible, and `make validate` checks every menu extension against your
declarations so you find out at build time instead.

## The third worked example: refreshing one thing when another changes

`git-treeview` exists for this shape: the working directory changed, so the file
tree's contents are wrong.

```lua
registry.on("cwd_changed", function()
  require("core.input.command").perform("treeview:refresh")
end)
```

...and the same `off(event, fn)` in `unload()`.

There is exactly **one** event in the registry today, `cwd_changed`. This is
deliberate: the editor has no general event system, so an event is worth adding
only when the alternative is polling. If you find yourself wanting a second one,
the honest first move is to wrap the function and call the original — which is
what the extension contract says to do, and what
[autocomplete](../plugins/autocomplete.md) does to three `RootView` methods.

## What not to build

**Do not build an integration with one dependency.** That is a `core/` plugin
with an extra directory. If you find yourself writing `X/integration/foo` that
only knows about `bar`, the answer is to put it in `X/core/` next to `bar` — or
to notice that `foo` and `bar` are the same plugin.

**Do not build a hub.** An integration that requires four other plugins and
re-exports their APIs is a `core/` plugin with extra steps, and it re-creates
exactly the coupling the category rule exists to prevent. If two integrations
both need the same thing, the shared part belongs in a module, not in a
third integration that depends on both.

**Do not duplicate a spelling.** If your integration needs to run `git status`,
require `X.core.git.recipes` and use `recipes.status` — do not write the string
again. That is the whole reason `recipes.lua` exists, and it is why the Git
menu section and the git commands cannot drift apart.

**Do not mark it essential.** `essential = true` means a cdin build cannot start
without it, and carries the constraint that it is copied alone and must be
self-contained. If you are integrating two plugins, both of them have to be in a
build for that to make sense, and the bundler copies exactly one plugin per
essential entry.

## Files to read

| file | what it shows |
| --- | --- |
| `X/integration/vim/vim-search/` | the smallest useful one: two dependencies, four keys, no commands |
| `X/integration/vim/vim-tab/` | ex-commands with aliases and path completion |
| `X/integration/vim/vim-window/` | two seams at once — `wmap` and `key` — and why one table serves both <kbd>Ctrl</kbd>+<kbd>W</kbd> and `:wincmd` |
| `X/integration/vim/vim-git/` | three files, and a menu section that quotes a user-supplied string |
| `X/integration/git-treeview/` | the one event there is |

[examples/03-vim-word-count](../../examples/03-vim-word-count) is a third one,
written to be read in one sitting.
