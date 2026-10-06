# Building a feature

A **feature** is a part of a package you can switch off. It is the other kind of
optional thing, and it is not the same as a [`with` entry](a-with-entry.md).

|  | feature | `with` entry |
| --- | --- | --- |
| what it is | part of *this* package | wiring to *another* package |
| declared as | `features = { … }` | `with = { … }` |
| lives in | `<package>/features/<key>.lua` | `<package>/with/<name>.lua` |
| keyed by | the feature's own name | the **partner's** package name |
| needs the partner | no | yes, by construction |
| gone when | you switch it off | the partner unloads, or the partner's feature under it does |

If you are reaching for a feature to make two packages talk to each other, you
want a `with` entry.

## The manifest

```lua
return {
  name = "basics",
  kind = "plugin",
  version = "0.1.0",
  description = "Reload files changed outside the editor and trim trailing whitespace on save",
  category = "core",
  min_cdin_version = "0.5.0",

  features = {
    autoreload = {
      default = true,
      description = "Reload a document when the file changes underneath it",
    },
    trimwhitespace = {
      default = true,
      description = "Trim trailing whitespace before every save",
    },
  },

  entry = "init.lua",
}
```

Each key is a **feature name**, and `description` is not decoration: the panel
draws it, and a feature with no description is a switch with no label.

## The file

```text
<package>/features/<key>.lua
```

Required as exactly that path — `scripts/check.lua` R8 looks for
`features/<key>.lua` and fails if it is elsewhere, because a feature whose file is
`features/autoreload-impl.lua` is a file the reader has to be told to find.

`default` is the state before you have expressed a preference. `true` here means
the feature is on in a fresh install; it does **not** mean you cannot turn it off,
and it does not persist.

## `enable` and `disable`

```lua
-- packages/editing/basics/features/trimwhitespace.lua
local command = require "core.input.command"
local Doc     = require "core.doc"

local M = {}

-- Hoisted so `disable` can hand back this exact table. Building it inline, as
-- this did before, means the removal has nothing to match: `command` and
-- `keymap` removals compare by identity.
local COMMANDS = {
  ["trim-whitespace:trim-trailing-whitespace"] = function()
    trim_trailing_whitespace(require("core").active_view.doc)
  end,
}

local enabled = false

--- Removes a function from one of the document hook lists, and says whether it
--- was there. The lists are plain arrays the host appends to, so undoing a
--- registration means finding the entry rather than replacing the list: the host
--- and every other package hold the same table.
local function remove_hook(list, fn)
  for i = #list, 1, -1 do
    if list[i] == fn then
      table.remove(list, i)
      return true
    end
  end
  return false
end

function M.enable()
  if enabled then return end
  enabled = true
  command.add("core.views.docview", COMMANDS)
  table.insert(Doc._before_save, trim_trailing_whitespace)
end

function M.disable()
  if not enabled then return end
  enabled = false
  command.remove("core.views.docview", COMMANDS)
  remove_hook(Doc._before_save, trim_trailing_whitespace)
end

return M
```

R8 requires both, and the reason is mechanical: the panel's feature switch, and
`Packages` invalidating every feature at shutdown, both call `disable` and have
nothing else to fall back on. A feature with only `enable` is a switch that turns
something on forever.

Three things this shape gets right that are easy to get wrong:

1. **`enable` and `disable` are each guarded.** Called twice, twice is a no-op.
   The kernel promises `init`/`unload` tolerate being called twice and in the
   wrong order, and features are no different.
2. **Removals get the *same* table or the *same* function.** `command.remove` and
   `keymap.remove` compare by identity; a table built fresh at removal time
   matches nothing and the registration survives the feature being switched off.
   The same is true of `registry.unregister_key` for a `with` entry.
3. **A hook list is *searched*, not replaced.** `Doc._before_save` is a plain
   array the host appends to and every other package holds a reference to, so
   undoing a registration means finding the entry. Assigning a new list would
   silently unhook the host and every other package.

## Where a user turns it off

**In the panel.** The package's line shows `2/3 off` when some are off, and
<kbd>F</kbd> on the line toggles the feature under the cursor. Feature rows are
drawn but **not cursor-selectable** — moving onto a feature row does not change
what <kbd>F</kbd> would toggle, because the row is not a row you can be *on*.

**In `packages.lua`**, beside your `init.lua`:

```lua
return {
  features = {
    basics = { autoreload = false },
    ["text-tools"] = { unicode = false },
  },
}
```

The bracket form for a hyphenated name is not a special case the package asks for;
it is what makes `text-tools` a valid `require` name and directory name at once.

## The order features are enabled in

Features of one package are enabled in the order the manifest lists them, and a
feature **may** require another of its own package — that is the one ordering
dependency features have, and it is why `tab-session` works: it subscribes to
`session.on_quit()`, so `session` has to be enabled first.

This is a *feature* dependency, not a package dependency, and it is spelled by
ordering rather than by a declaration. The harness asserts the order rather than
trusting it, which is the whole of the guarantee: nothing stops you from writing
two features that each need the other, and the failure is at load rather than
silently at 3am.

## What a feature may not do

| | |
| --- | --- |
| declare its own `kind`, `version`, `min_cdin_version` | those are the package's |
| name a partner package | that is a `with` entry |
| exist outside `<package>/features/` | R8 looks for that exact path |
| omit `disable` | R8 requires both |
| be a `<package>/<name>/` directory | that is how `workspace`'s `tab`/`window`/`session` are shaped, and it is a package, not a feature |

That last row is worth reading twice, because it is the one place the shape is
overloaded. `packages/navigation/workspace/tab/` is a directory with its own
`init.lua`, `commands.lua`, `keymap.lua` and `README.md` — too big to be a
feature, and it is treated as one because it is a *part* of the package rather
than a package. Its `enable`/`disable` come from the same place a feature's do.

## See also

- [writing a plugin](../writing-a-plugin.md) — the whole shape first.
- [building a with entry](a-with-entry.md) — the other kind of optional part.
- [workspace](../plugins/workspace.md) — a package with four features, as it
  really looks.
- [basics](../plugins/basics.md) — the smallest package with two.