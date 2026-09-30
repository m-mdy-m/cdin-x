# menu

A menu: sections, entries, a letter for each, and a line to type into.

You have probably never installed this on purpose. It is not something you
open. It is the thing <kbd>m</kbd> opens in vim mode, the thing the extension
manager's panel is built from, and the thing other plugins add sections to.
Install it and the parts of the editor that show you a list start working.

## Using a menu

<kbd>m</kbd> in vim mode, if `vim-menu` is installed. Or `menu.open("…")` from
your own code.

It is the command palette's prompt, with sections. That means the same keys:

| key | does |
| --- | --- |
| type | filter |
| <kbd>↑</kbd> / <kbd>↓</kbd> / <kbd>Tab</kbd> | move |
| <kbd>Enter</kbd> | run the highlighted entry |
| <kbd>Esc</kbd> | close |

**Typing filters, and filtering is a plain substring, case-insensitive.** It
is matched against an entry's label *and* its hint text, so `gt` finds an entry
labelled "Git: Tab" and also one whose hint says "git". It is not fuzzy —
`gtb` will not find "Git: Tab", because those letters are not contiguous. If
you want subsequence matching, that is the palette's business, not this one's.

**A single letter runs an entry directly.** Every entry has a letter in its
left column, and if what you typed is exactly one character and an entry claims
it, that entry runs — the filter is not consulted. This is why sections pick
letters carefully, and why a single character is a shortcut rather than a
one-letter search.

## What is in the menu

`vim-menu` defines four sections of its own:

| section | what it does |
| --- | --- |
| Files | new, open, save, close, recent files |
| Navigate | the file finder and the folder prompt |
| Build | run a command, `make`, a custom build |
| Shell | run a shell command, open a terminal |

Two more come from other integrations, and they are the clearest example of why
this plugin exists as a separate thing:

| section | from | what it does |
| --- | --- | --- |
| Git | `vim-git` | status, log, diff, add, commit, push, pull, branches |
| CDIN-X | `vim-plugin-manager` | the extension manager |

`git` is a whole capability — process discovery, status, ignore rules — and it
knows nothing about menus. `vim-git` is the one file that knows both. Uninstall
`vim-git` and the Git section disappears cleanly; `git` keeps working, because
it never knew the section was there.

## Building on it

Six functions, from `X.core.menu.impl`.

### Defining a menu

```lua
local menu = require "X.core.menu.impl"

menu.define("my.menu", {
  title   = "My Menu",
  context = function() return { label = "the current file" } end,
  entries = function(context)
    return {
      { key = "a", label = "Do the thing", info = "in the document",
        action = function() ... end },
    }
  end,
})
```

`entries` and `context` are functions, called every time the menu opens. That is
the whole reason a section can depend on state.

### Adding to somebody else's menu

```lua
menu.extend("vim.main", "my-section", function(context)
  return {
    header  = "Mine",
    entries = { { key = "z", label = "Zap", action = zap } },
  }
end, 50)   -- order: lower comes earlier; omitted means 100
```

Sections run in ascending `order`, and equal orders run in registration order —
so a section that has to come first should say so rather than rely on who
loaded first.

`menu.extend` **asserts** that the menu exists. So if you are extending
`vim.main`, depend on `vim-menu` — the integration that *defines* that menu —
and not merely on `menu`, the capability that owns menus. The catalog is
scanned with `pairs()`, so load order is not stable between runs, and getting
it wrong gives you `menu is not defined: vim.main` on some runs and not others.
It is the worst shape a load-order bug can have.

```lua
menu.remove_extension("vim.main", "my-section")
```

### Context

```lua
menu.set_context_provider("vim.main", "my-section", function()
  return { label = "read-only" }
end, 10)

menu.remove_context_provider("vim.main", "my-section")
```

This looks like a way for several plugins to contribute to one hint line. It
is not. Providers are sorted by priority, highest first, and **the first one
that returns something wins**; the rest are not called. The menu's own
`context` is the fallback if every provider returns nil. So a provider is a
claim on the context, not a contribution to it — and the fallback chain is what
makes a section that only applies to some situations work at all:

```lua
menu.set_context_provider("vim.main", "mine", function()
  if not read_only() then return nil end      -- stays out of the way
  return { label = "read-only" }
end, 10)
```

A provider that never returns nil, rather than one that does, is a provider
that has taken the context away from everybody.

### Opening one

```lua
menu.open("vim.main")        -- true if it opened
menu.open("vim.main", { label = "something else" })   -- with a context
```

## How it works

**A menu is a name and a lookup, not a thing.** `define` puts a spec in a table
keyed by a string; `open(name)` looks it up and runs it. Nothing holds a
reference to a menu, which is why a plugin can extend a menu another plugin
defines without either of them knowing the other's name at load time.

**Sections are addressed by id, and the id is what you unregister with** — not
by the header string. Two sections may both be headed "Files"; the header is
for reading and the id is for addressing. That is what makes
`remove_extension` remove *your* section and leave the other one alone when
both plugins are installed.

**`menu` is a `core/` plugin, so it may not require another X plugin.** That is
the rule keeping this from becoming a hub where everything knows everything. The
primitive knows about sections; a section knows about the primitive; neither
knows what is in the other.

**The prompt is `core.command_view`.** Not a widget of its own — the same
prompt the command palette uses, which is why the keystrokes are the same and
why the argument can be either a typed string or a chosen item. The title says
so: it opens as `Menu  (key / ↑↓ / Tab)`.

**Entry order in the list is registration order, and it is not stable across
installs.** Sections sort themselves, but the sections themselves come out of a
`pairs()` walk. If the order of two sections matters to you, that is what the
`order` argument is for.

## Files

| file | holds |
| --- | --- |
| `impl.lua` | the registry, section ordering, context, the open loop |
| `init.lua` | the manifest and the load guard |
