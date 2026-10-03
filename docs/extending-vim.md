# Extending vim mode

Vim mode is one of the two plugins a cdin build cannot start without, so it is bundled
into the editor rather than installed beside everything else. That has a
consequence worth stating plainly: **vim core cannot know what tabs are.**

It cannot know about the file tree, or search, or git, or the plugin manager,
or any of the other capabilities cdin has. If vim mode grew a `:tabnew` of its
own, then removing the tab plugin would leave a `:tabnew` that quietly did
nothing — which is the exact failure this arrangement exists to make
impossible.

So vim mode offers seams, and the plugins that fill them live in
`X/integration/vim/`. Everything below goes through one module:
`X.core.vim.registry`.

## The seven seams

| call | what it claims | resolved by |
| --- | --- | --- |
| `register_command(spec)` | an ex-command: `:tabnew`, `:split`, … | the `:` line and its completion |
| `register_key(map)` | one normal-mode key | the normal-mode key reader |
| `register_visual_key(map)` | one visual-mode key | the visual-mode key reader |
| `register_gmap(map)` | a `g`-prefixed sequence: `gt`, `gT` | the normal-mode key reader |
| `register_wmap(map)` | a character after <kbd>Ctrl</kbd>+<kbd>W</kbd>, or after `:wincmd` | both readers, which is why one seam covers two |
| `register_action(id, fn)` | a named function other plugins can call | nothing, until someone calls it |
| `on(event, fn)` | a notification | whoever emits it |

Each has a matching `unregister_*`, and a plugin that registers is expected to
unregister — see [writing-a-plugin.md](writing-a-plugin.md) for why that is not
optional.

### ex-commands

The one with a spec, because an ex-command has more to it than a function:

```lua
local registry = require "X.core.vim.registry"

local specs = {}

function M.register()
  specs = {
    {
      names     = { "tabnew", "tabe", "tabedit" },
      arg_paths = true,                       -- the : line offers path completion
      help      = "--    :tabnew [path]  open a new tab, optionally with a file",
      run       = function(arg)
        require("core.input.command").perform("tab:new")
        if arg then open_file(arg) end
      end,
    },
  }
  for _, spec in ipairs(specs) do registry.register_command(spec) end
end

function M.unregister()
  for _, spec in ipairs(specs) do registry.unregister_command(spec) end
  specs = {}
end
```

`names` is a list rather than a string because `:tabe` and `:tabedit` are the
same command and should stay the same command — aliases registered against one
spec, so `:help` lists them together and unregistering removes all of them at
once.

`help` is what `:help` prints, and it is why these plugins don't each patch the
help text: the registry collects every distinct `help` string and prints them
in registration order.

### keys and sequences

The three key seams take a map, and a map is a table, which means you keep the
reference you registered so you can hand it back:

```lua
local registry = require "X.core.vim.registry"

local keys = { ["H"] = function(view) vim_go_top(view) end }
local gmap = { ["gt"] = function(n) tabs().next(n) end }

function M.register()
  registry.register_key(keys)
  registry.register_gmap(gmap)
end

function M.unload()
  registry.unregister_key(keys)   -- the same table, not a copy
  registry.unregister_gmap(gmap)
end
```

Unregistering is by identity: the registry removes an entry only if the value
is still the one you registered. That's what lets two plugins both answer to
`H` and lets the later one win without the earlier one's `unload` deleting it
out from under it.

**Register a key the host reports by name under that name.** `register_key` is
asked about the key as the host spells it, before vim mode rewrites it: `tab`,
`home`, `space`, `pageup`, `f3`, and the shifted spellings `shift+n` for a
capital and `*` for the character itself. So `["tab"]` works, which is how
`vim-window` moves panes — and a key vim mode *does* implement, spelled as a
motion (`home` is `0`, `end` is `$`, `space` is `l`), never reaches the registry
while a document has focus, because vim is asked first.

Anything the registry declines goes on to the editor's own keymap, unless it is a
single printable character — those are swallowed, because vim beeps at a letter
it does not know and swallowing is what the beep is made of.

### actions

A named function, for capabilities that want to be callable rather than
reachable by a key:

```lua
local vim = require "X.core.vim.api"   -- an alias for the registry
vim.register("my.capability", function(arg) ... end)
vim.call("my.capability", arg)
```

`X.core.vim.api` is the older spelling of the same three calls. New code should
use the registry; the alias is there so an existing integration keeps working.

### events

`on(event, fn)` / `off(event, fn)` / `emit(event, ...)`, and there is exactly
one event today: `cwd_changed`. It fires when the working directory changes, and
`vim-treeview` uses it to refresh the tree.

This seam is thin on purpose. The editor has no general event system — see
[the extension contract](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md)
— so extending behaviour means wrapping the function and calling the original.
An event is worth adding when the alternative is polling.

## A whole integration

`X/integration/vim/vim-tab/` is about sixty lines and shows the shape:

```lua
-- init.lua
local M = {
  name         = "vim-tab",
  version      = "0.2.0",
  description  = "Vim tab commands backed by the CDIN tab plugin",
  category     = "integration",
  type         = "plugin",
  essential    = false,
  dependencies = { "vim", "tab" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.vim.vim-tab.commands").register()
  require("X.integration.vim.vim-tab.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-tab.keymap").unregister()
  require("X.integration.vim.vim-tab.commands").unregister()
  loaded = false
end

return M
```

Two things to notice.

**It depends on `tab`, and says so.** That declaration is what the manager
sorts on, so `tab` is loaded before this. It is also what `make validate`
checks every cross-plugin `require` against — an integration that requires
`X.core.tab.manager` without listing `tab` in `dependencies` fails the gate.

**It is the only file under `X/` that mentions `X.core.tab` outside this page.** That is
the entire point of the arrangement: one place where the two capabilities meet,
so either one can be removed without leaving the other half-wired.

## Which integration to copy

| you want | read |
| --- | --- |
| ex-commands and `gt`/`gT` | `X/integration/vim/vim-tab/` |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> splits | `X/integration/vim/vim-window/` |
| `/ n N *` over the search plugin | `X/integration/vim/vim-search/` |
| a section in the <kbd>m</kbd> menu | `X/integration/vim/vim-menu/` |
| git commands, and a menu for them | `X/integration/vim/vim-git/` |
| `:tree`, and the tree in vim | `X/integration/vim/vim-treeview/` |
| the manager, from vim | `X/integration/vim/vim-plugin-manager/` |

If you're adding a menu section to a menu another integration defines, read
[the note on `menu.extend`](../X/integration/README.md) first — it *asserts*,
and an integration that extends a menu has to declare the integration that
defines it, not just the capability that owns menus.
