# Contributing to cdin-x

## Start here

```sh
make validate
```

On a clean checkout, before anything else. It is the gate CI runs, and it is
fast enough to run on every save.

When it fails, read the failure as a rule rather than a typo. Nearly every rule
below exists because of a specific failure that was hard enough to find twice.

## Adding a plugin

```sh
lua scripts/new-plugin.lua <name> [core|integration|optional|syntax|themes]
```

Which category you pick is a decision, not a formality, and
[`X/README.md`](X/README.md) is the one page that lays out what each one
means. The short version: if your plugin does one thing, it is `core`; if it
connects two things that must not know about each other, it is `integration`;
if people might not want it, it is `optional`.

Then read [docs/writing-a-plugin.md](docs/writing-a-plugin.md), and copy
whichever of the [examples/](examples/) is closest to what you want. The parts
that are not obvious:

**The manifest is inline** in `init.lua`. There is no `manifest.lua`, anywhere,
for any plugin.

**Nothing is required at the top of `init.lua`.** The catalog `dofile`s the
entry point to read the manifest, so a top-level `require` would run your whole
subtree's side effects just to look the plugin up. Requires go inside `init()`.

**`init(core, config)` takes two arguments, positionally.** The runtime calls
`mod.init(core, config)`, so `function M.init()` works and
`function M.init(config)` compiles and then reads the core table as your config.
This one is worth checking by eye rather than by testing.

**`init()` must tolerate being called twice.** A plugin `dofile`d once by the
catalog and `require`d once by an integration is two module instances with two
independent guards, and without a guard both of them do the work.

**`unload()` undoes everything `init()` did.** Commands, key bindings, menu
sections, status pills, help entries. Keep the handle
`core.register_help_shortcuts` returns and hand it back.

## The rules, and what each one is for

1. **A cross-plugin `require` needs a declared dependency.** If you require
   something another plugin owns, that plugin is in your `dependencies`. The
   manager sorts the load order on that declaration
   (`cdinx/manager/deps.lua`), so it is not documentation — it is what makes
   the order right.

2. **`X/core/` and `X/optional/` may not require another X plugin.** The
   wiring goes in `X/integration/`, which is allowed to. The alternative is a
   plugin that works until somebody uninstalls the other one, and a catalog
   nobody can reason about.

3. **Every declared dependency exists in the tree.** A typo in a dependency
   name is otherwise a silent no-op: the sort is given a name nothing provides,
   and nothing complains.

4. **The essential set is counted.** Exactly one essential *theme*, because a
   build that bundles two themes has no answer to which one to start with. The
   plugin count is reported but not bounded — `vim` and `manager` are both
   essential today, and a third would pass validation silently. If you are
   adding one, the check needs extending in the same change.

5. **Every essential plugin is self-contained.** Its `require "X.…"` calls all
   resolve inside its own directory. There is no cheap static check for this —
   an essential plugin is copied *alone*, so the only true test is to copy it
   somewhere by itself and see whether it still loads. That is a real bundler
   run, which is why `validate` does one.

6. **Nothing under `cdinx/` or `X/` mentions `EXEDIR` or `core.x`.** cdin-x
   does not know where the editor is installed, and there is no sibling
   checkout. `config.site_path()` is the whole of what it knows about paths,
   and it is the host's own resolver rather than one computed here.

7. **`init()` and `unload()` are symmetric**, and a `register()` a plugin calls
   exists on the module it calls it on.

   Rule 7 is here because a missing `register()` is the one failure that looks
   like success. The manager's `pcall` catches the raise, but by then the
   plugin has already been reported as loading, and the
   `attempt to call a nil value` is one line among forty in a log nobody opens.
   Three plugins sat broken that way for long enough to be written down as
   known issues.

## Do not depend on load order

The catalog is walked with `pairs()`, so the order plugins load in is **not
stable between runs**. Anything that assumes another plugin has already run
needs a `dependencies` entry.

The case that keeps coming up is `menu.extend(name, …)`, which *asserts* that
the menu exists. An integration extending a menu has to declare the
integration that **defines** it, not merely the plugin that owns menus.
`{ "vim", "menu" }` and then extending `vim.main` is a coin flip;
`{ "vim", "menu", "vim-menu" }` is a guarantee. The failure is
`menu is not defined: vim.main` — on some runs and not others, which is the
worst shape a load-order bug can have.

## What not to do

**Do not mark something essential to get it into a build.** `essential = true`
means *a cdin build cannot start without this*, and it carries the constraint
that the plugin gets copied alone and has to be self-contained. If a plugin is
generally useful, it belongs in the optional set and the user installs it.

**Do not reach into the editor's tree.** `config.site_path()` is the whole of
what cdin-x knows about where things are. No `EXEDIR`, no sibling checkout, no
guessing where cdin was installed from. Validate will fail, and rightly.

**Do not fetch at runtime.** The registry syncer is a function an extension
registers; the manager never shells out to git itself, because the git plugin
may be absent and a bare editor must still boot.

**Do not reformat files you are not changing.** The tree is LF. Two files are
CRLF: `X/manifest.lua`, which `scripts/generate-manifest.lua` writes that way
deliberately — the comment at the top of that file explains why — and
`X/core/treeview/treeview_impl.lua`.

Nothing enforces this, which is worth knowing: the pre-commit hook runs
`make validate` and nothing else, and `validate.lua` has no line-ending check.
So a mass reformat is caught by review, or not at all. A reformat turns a
three-line diff into a review nobody can do, which is the real cost — and it is
also why a reviewer who spots one should say so rather than approving it.

If you want the tree to stop depending on that, a `mixed-line-ending` check in
`validate.lua` is a small addition and would belong there rather than in a hook.

## Style

`snake_case` throughout.

Comments explain *why*, and say what breaks if the line changes. A comment
restating the line above it is noise. When a comment is long enough to need its
own paragraph, it has usually discovered that the code needed a different shape.

A file opens with a comment saying what it is and **what it refuses to do**. The
conventions here are worth matching, and not only in the code: the next person
deciding whether `X/core/vim` may require something else should find the answer
at the top of the file.

Keep functions short. A four-hundred-line function is a sign the file is doing
two things.

## Adding a theme

```sh
lua scripts/new-plugin.lua <name> themes
```

`X/themes/<name>/theme.lua`, with `essential = false` unless it is replacing
the default. Run `make manifest` afterwards — the catalog is generated.

## Before you open the pull request

1. `make validate`
2. `make manifest`, and commit `X/manifest.lua` if it changed
3. `lua scripts/plugin-list.lua` — check the entry reads the way you meant
4. A `README.md` for the plugin: what it is, what keys it takes, what it needs
   from the host. Two or three sentences is plenty; a directory README is an
   introduction, not a manual.
5. `CHANGELOG.md` under `[Unreleased]`, if it is a change a user would notice.

## Reporting a bug

`validate`'s output first, then `make list` so we are looking at the same
catalog you are. If the problem is a plugin failing at load, the reason is in
cdin's log — `core:open-log`, or <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> —
and that is usually the whole answer.
