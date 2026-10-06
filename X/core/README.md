# X/core

`vim`, and nothing else. Every other first-party package has moved to
`packages/<domain>/<name>`, where a `package.lua` makes its identity its name and
its modules required as `require "vim.registry"` rather than by where it sits.

**The move is finished.** `X/integration/` is gone too — it held eight packages
whose only content was wiring between two other packages, and those are now `with`
entries: files inside one of the two, run only while both are loaded.

## vim

Vim mode, the ex command line, the shell escape, the modal editor, and seven
seams to other packages.

```text
vim/
  package.lua    the manifest: five partners, seven `with` entries
  init.lua       the one load point, and the definition of `vim.main`
  registry.lua   the extension points the seams register into
  commands.lua   vim's own cdin commands
  keymap.lua     vim's own non-modal key bindings
  ex/            the ":" command line, split by concern
  shell/         running shell commands and showing their output
  vimode/        modal editing: key reader, motions, text objects, operators, mode
  with/
    git.lua             + git/            needs git
    menus.lua           + menus/          needs menu
    plugin-manager.lua  + plugin-manager/ needs menu
    search.lua          + search/         needs search
    tab.lua             + tab/            needs workspace
    treeview.lua        + treeview/       needs treeview
    window.lua          + window/         needs workspace
```

Each `with/<name>.lua` is one seam: an `enable()` and a `disable()`, and a
directory beside it holding the modules that seam owns. It runs only while both
packages are loaded, and comes down when either leaves — so vim works with none of
them installed, and so does each of them without vim.

**The key in `with` is the package, never the seam.** That is what lets `validate`
check what a seam is allowed to reach: a seam may reach the one package its own
key names, and nothing else. Two seams waiting on one package is a list under
that one key — which is why `menu` and `workspace` each carry two paths.

**`vim.main` is defined in `init.lua`, not in `with/menus.lua`.** Four seams call
`menu.extend` or `menu.set_context_provider`, and both *assert* the menu exists. If
the definition lived in an optional seam, whether an extender worked would depend
on two optional things happening to load in the right order. Init always runs
first, so the menu is always there.

That is also why `with/menus/menu.lua` takes the menu registry as an argument
rather than requiring it: init already has to reach for it under a `pcall`,
because the `menu` package is optional, and a top-level `require` there would put
that dependency back into a file that has to be loadable without it.

## Nothing here is mandatory

There is no `essential` field and nothing replaces it. What a build carries is
decided by a bundle in `../../bundles/`. `make bundle BUNDLE=minimal` produces the
kernel, its shim and the fonts, and nothing else.

`bundles/standard.lua` names `vim` and `themes`, so a standard build has vim mode
with none of its seven seams — no git, no treeview, no workspace, no menu. That
is the intended shape: vim is one package with seven optional parts, not seven
packages that happen to need vim.

## The config keys are the host's

`config.vim_mode_enabled` is written at the top level, not namespaced, because the
**host** reads it. `config.vim.vim_mode_enabled` would be a key nothing reads, and
vim mode would be silently off with no obvious cause — every gate tests
`if not config.vim_mode_enabled then return false end`.

## Commands and keys did not change

`vim-git:status`, `vim-menu:open`, `vim-fmenu:open`, `vim-shell:git-log` and every
keystroke are exactly as they were. Only the package and directory names moved:
`X.core.vim.registry` is now `vim.registry`, and `X/integration/vim/vim-git/` is
now `X/core/vim/with/git/`.

Details: [docs/writing-a-plugin.md](../../docs/writing-a-plugin.md).