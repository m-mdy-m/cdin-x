# Writing a plugin

A plugin is a directory with an `init.lua` in it, or a single `.lua` file. The
editor hands it two arguments and then gets out of the way.

That's the whole contract. Everything below is either that contract, or a rule
this repository enforces on the plugins it ships, with the reason it enforces
it.

## Where yours lives

Not here.

This repository is the catalog. Your plugin is yours, in your own directory,
anywhere on disk — and **Install Local** in the manager installs it from that
path into your extension store. That's the whole workflow: edit in your
checkout, re-install, see the change.

You only add a plugin *here* if you want it in the catalog for other people,
which is a different job with a different bar (see
[CONTRIBUTING.md](../CONTRIBUTING.md)).

## The smallest one that does something

```lua
-- hello/init.lua
local M = {
  name        = "hello",
  version     = "0.1.0",
  description = "Says hello",
  category    = "optional",
  type        = "plugin",
  essential   = false,
}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  require("hello.commands").register()
  require("hello.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("hello.commands").unregister()
  require("hello.keymap").unregister()
  loaded = false
end

return M
```

```lua
-- hello/commands.lua
local M = {}
local command = require "core.input.command"

function M.register()
  command.add(nil, {
    ["hello:say"] = function()
      require("core").log("hello")
    end,
  })
end

function M.unregister()
  command.remove(nil, { ["hello:say"] = true })
end

return M
```

```lua
-- hello/keymap.lua
local M = {}
local keymap = require "core.input.keymap"

function M.register()
  keymap.add { ["ctrl+alt+h"] = "hello:say" }
end

function M.unregister()
  keymap.remove { ["ctrl+alt+h"] = "hello:say" }
end

return M
```

Save that, point **Install Local** at the directory, and <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>H</kbd>
does the thing. No build, no restart.

## The manifest is in `init.lua`

There's no `manifest.lua`. The table `init.lua` returns *is* the manifest —
name, version, description, category, type, essential, dependencies.

That is a deliberate choice, and the reason is the next section.

## Nothing is required at the top of `init.lua`

This is the rule people hit first, so it is worth saying why.

The catalog has to know a plugin's name and dependencies *before* it decides
what order to load things in. It gets them by running `dofile()` on the entry
point and reading the returned table. A `require` at module scope would run
that plugin's whole subtree — every registration, every side effect — purely so
the catalog could look up a name.

So the entry point's top level is a manifest and nothing else. Everything real
goes inside `init()`:

```lua
-- no
local command = require "core.input.command"
command.add(nil, { ["x"] = f })

-- yes
function M.init(core, config)
  require("x.commands").register()
end
```

## `init()` may be called twice

The guard is not decoration. A plugin `dofile`d by the catalog and then
`require`d by an integration is **two module instances with two independent
guards** — the second one sees `loaded == false` and does all the work again.
The result is two copies of every command, and a key binding that fights
itself.

```lua
local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  -- ...
end
```

## `unload()` has to undo all of it

Every command removed, every key binding removed, every menu section removed.
A plugin that leaves a key behind will fight the next thing to bind that key,
and a plugin that reloads accumulates one copy of its registrations per load.

For help entries, keep the handle and hand it back:

```lua
function M.init(core, config)
  M.help_handle = core.register_help_shortcuts { { "ctrl+alt+h", "Say hello" } }
end

function M.unload()
  core.unregister_help_shortcuts(M.help_handle)
  M.help_handle = nil
end
```

## Where things live, and what may depend on what

If your plugin is going into this repository, it goes in a category, and the
category is a rule rather than a label:

| directory | holds | may depend on |
| --- | --- | --- |
| `X/core/` | one capability each | the host, and itself |
| `X/integration/` | the wiring between capabilities | two or more other plugins |
| `X/optional/` | genuinely optional plugins | the host, and itself |
| `X/syntax/` | language definitions | the host |
| `X/themes/` | themes, as `<name>/theme.lua` | the host |

The rule that makes the catalog checkable: **a `X/core/` plugin may not depend
on another X plugin.** Not may not *prefer* to — may not, at all.

The alternative is a plugin that works right up until somebody uninstalls the
other one, and a catalog you can't reason about. If two plugins genuinely need
to know about each other, that knowledge goes in `X/integration/<name>/`, which
declares the dependency in its manifest so the manager can order the load.
`make validate` enforces all of this.

## `essential = true` means something specific

Two plugins and exactly one theme carry it: `vim`, `manager`, and the `default`
theme. A cdin build bundles them in, so a build with nothing else installed
still opens a working editor with a reachable extension panel.

Because an essential plugin is copied **alone**, every `require "X.…"` inside
it has to resolve within its own subtree. The bundle contains that plugin and
nothing else, so a require that escapes it resolves to nothing — and it fails
at *startup in a built editor*, which is the worst place to find out.

`manager` is the one essential plugin whose code is not under `X/`: it lives at
the checkout root, in `cdinx/`. Rather than have the bundler guess at what an
essential plugin needs, the plugin says so:

```lua
bundle_with = { "cdinx" },
```

and `scripts/bundle.py` copies those paths in beside it, layout intact. An
undeclared dependency is a build whose editor starts and then does nothing, and
nobody should have to debug that at runtime.

`make validate` checks the self-containment rule. It does **not** yet check
`bundle_with` in either direction — see the known issues in the changelog.

If you're not sure whether a plugin is essential, it isn't.

## Themes

```
X/themes/<name>/theme.lua
```

One file, a table of colors, and that's the layout cdin's theme registry reads
— so a theme directory can be handed to `core.themes.add_root()` as-is. The
manager installs themes but never loads them; the host's registry does.

## Commands and keys, in one place each

Commands are registered by name with an optional predicate:

```lua
command.add(nil, { ["hello:say"] = run })                  -- always
command.add("core.views.docview", { ["hello:word"] = run }) -- only in a doc
```

`nil` for the predicate means always. The string form is the command's own
context, so `core.views.docview` is how you say *in a document view*.

Keys map keystrokes to command names, and never to functions:

```lua
keymap.add { ["ctrl+alt+h"] = "hello:say" }
```

Binding a name rather than a function is what lets <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
find and run your command without knowing that it exists.

**A stroke is spelled, not described.** The editor builds the string it looks
up — every modifier held, in the order `ctrl`, `alt`, `altgr`, `shift`, then
the key's own name — and matches that string for equality, with no
normalisation, aliases or case folding. So the modifiers have to be written in
that order: `ctrl+alt+shift+n`, not `ctrl+shift+alt+n`, and a key is one name,
lowercase, with no `+` inside it. A stroke spelled any other way is not a near
miss, it is a string no key press produces — a binding that can never fire and
says nothing when it does not. `["ctrl+shift+alt+n"]` shipped in treeview that
way. The host now reports every such stroke in the log at boot, and
`make validate` fails on one before it ships.

Both have matching `remove`, and a plugin that registers is expected to
unregister.

## What `make validate` will tell you

It's the gate, and every rule it enforces is a failure mode that's invisible
until much later:

- a required file is missing
- no essential plugin, or not exactly one essential theme
- `fonts/` missing or empty
- a `require` that crosses a plugin boundary without a declared dependency
- a `register` without a matching `unregister`
- an `EXEDIR` reference, or the old `core.x` namespace, anywhere in `cdinx/` or `X/`
- a keystroke no key press can produce — wrong modifier order, an uppercase
  key, a `+` inside the key, or a modifier the input layer does not report
- an essential plugin that isn't self-contained
- and finally it **runs the real bundler twice** and compares, so the thing a
  cdin build consumes is checked rather than assumed

```sh
make validate
```

## Working on one without installing it

`make link` (or `make link SITE=/path`) symlinks this checkout into your site
directory, so a change to a plugin here is a restart away rather than an
install. That's the reason `make link` exists as a separate target from
`make install`, and the reason to use it while you're still moving things
around.

## Working examples

Three, in [`examples/`](../examples), each small enough to read in one sitting:

| example | shows |
| --- | --- |
| [`01-hello`](../examples/01-hello) | the minimum: one command, one key, a clean unload |
| [`02-word-count`](../examples/02-word-count) | reading a document, a view that owns the status line |
| [`03-vim-word-count`](../examples/03-vim-word-count) | extending vim mode through its registry, from `X/integration/` |

## What cdin guarantees

The loader, the command and key registries, the theme registry, and
`core.command_view` are cdin's half of this, and they have their own document:
[the extension contract](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md).
Read it before you rely on anything not listed there — in particular, there is
no hook or event system, so extending something means wrapping the function
and calling the original.
