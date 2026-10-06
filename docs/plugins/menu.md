# menu

A menu: sections, entries, a letter for each, and a line to type into.

You have probably never installed this on purpose. It is not something you
open. It is the thing <kbd>m</kbd> opens in vim mode, the thing the extension
manager's panel is built from, and the thing other plugins add sections to.
Install it and the parts of the editor that show you a list start working.

## Using a menu

<kbd>m</kbd> in vim mode, with `vim` installed. Or `menu.open("…")` from
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

**A single letter runs an entry directly — and it is the *first* character, not
the whole input.** Every entry has a letter in its left column, and the submit
handler looks up `text:sub(1,1)`. So `g` runs the `g` entry — and so does `git`,
`go`, or anything else beginning with `g`. The rest of what you typed is
discarded and the filter is never consulted.

The live filter has the same short-circuit, and it is worse: after you type one
character that some entry claims, the list collapses to that entry and stops
narrowing. Typing `gits` shows you the `g` entry and nothing else.

This is why sections pick letters carefully. It is also the one place where this
menu behaves differently from the palette, which is fuzzy
throughout and never short-circuits on a letter.

## What is in the menu

vim's `with` entry on `menu` defines four sections of its own:

| section | what it does |
| --- | --- |
| Files | new file, new directory, open, rename, copy, move, delete |
| Navigate | change directory, up one level, current directory, working directory |
| Build | `make`, `make test` |
| Shell | a custom command, the environment, network info |

Four more come from other `with` entries, and they are the clearest example of why
this plugin exists as a separate thing:

| order | section | from | what it does |
| --- | --- | --- | --- |
| 20 | Tree | vim `with` on `treeview` | refresh, and jump into the file tree |
| 30 | Git | vim `with` on `git` | status, log, diff, add, commit, push, pull, branches |
| 40 | Search | vim `with` on `search` | find, replace, project search |
| 80 | CDIN-X | vim `with` on `menu` | the extension manager |

The `with` entry on `treeview` also registers the menu's only context provider,
at priority 200 — which is why the title shows the tree's state rather than the
`with` entry's own idea of it.

`git` is a whole capability — process discovery, status, ignore rules — and it
knows nothing about menus. The `with` entry on `git` is the one file that knows
both. Remove `git` and the Git section disappears cleanly; `git` itself keeps
working, because it never knew the section was there.

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

`menu.extend` **asserts** that the menu exists. That is a deliberate sharp edge,
and it is why `vim.main` is defined in `vim/init.lua` rather than inside
`with/menus.lua`: the menu has to be defined before anything can extend it, and
`init.lua` is the one place that is guaranteed to run first.

**A `with` entry is the right way to extend another package's menu**, because the
kernel only builds an entry once its partner is already up. There is no
`menu is not defined: vim.main` on some runs and not others any more — the failure
that used to need an ordering dance to avoid cannot happen when the ordering is
the mechanism.

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

**This plugin registers no commands and binds no keys.** Every keystroke in the
table above belongs to `core.command_view`, the host's prompt. `menu` is six
functions and a registry; with `vim` installed you get the <kbd>M</kbd>
binding from the `with` entry, not from here.

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
why the argument can be either a typed string or a chosen item. The title is the
menu's own `title` (or its name), the context's label when there is one, and
then `(key / ↑↓ / Tab)`.

**Section order is `order`, then registration order.** Providers sort ascending
by `order`, and ties break on the sequence number they were registered with, so
once two sections have different `order` values the list is deterministic.
`pairs()` only reorders providers that tie — which is the case to avoid rather
than one to document.

**Ties break the two ways round.** `extend` breaks on the *lower* registration
number, so the first section registered comes first. `set_context_provider`
breaks on the *higher* one, so the most recently registered provider wins. Both
are one-line comparisons and neither is commented where you would want it.

**The filter matches the rendered row, not the model.** An entry is drawn as
`[x] label` with a `├─ ` / `└─ ` prefix and section headers as `── Header ──`,
and the substring test runs against that string. So `[`, `]`, `─` and `└` are
searchable characters, and a section header matches on its own text.

**Two entries with the same letter disagree.** The submit path builds its key
table by assignment, so the **last** one wins; the filter scans in order and
returns the **first**. Press <kbd>Enter</kbd> and you get one entry, keep typing
and you see the other.

**`define` is destructive.** It replaces the whole entry for a name, dropping
every provider and context registered against it. Re-defining `vim.main` after
other `with` entries have extended it silently removes their sections; nothing
warns.

**Unload is one line.** It sets `core.menu = nil` and removes no section,
because the package keeps no registry of who extended what. If you care that your
sections disappear, your own `disable()` has to do it — and vim's `with` entry on
`menu` does, which is why removing it can leave a stale `vim.main` in the table.

## Files

| file | holds |
| --- | --- |
| `impl.lua` | the registry, section ordering, context, the open loop |
| `init.lua` | the manifest and the load guard |
