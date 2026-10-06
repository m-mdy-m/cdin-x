# integration

The wiring between capabilities. Nothing here implements anything — these
directories exist so that two plugins which must not know about each other can
still meet.

| directory | connects | status |
| --- | --- | --- |
| `git-treeview/` | git status → tree badges and refresh | stays |
| [`vim/`](vim) | vim mode ↔ everything else | goes in Phase 5, into `vim/with/` |
| `session/theme-switcher/` | the theme switcher → the session's saved theme | **gone** — part of `themes` |
| `tab-session/` | the tab manager ↔ persistent session state | **gone** — a feature of `workspace` |

An integration declares what it needs in its manifest, and that declaration is
what the manager sorts the load order on:

```lua
dependencies = { "vim", "git" }
```

`make validate` checks every cross-plugin `require` and every menu extension
against those declarations. A `require` with nothing behind it fails the build,
which is the point — the alternative works until the other plugin is removed.

**One trap.** `menu.extend(name, …)` *asserts* that the menu exists, so an
integration extending a menu must declare the integration that **defines** it,
not just the plugin that owns menus. Declare `menu` and extend `vim.main` and
you get `menu is not defined: vim.main` on some runs and not others. The full
story is in [docs/extending-vim.md](../../docs/extending-vim.md).

**Full page:** [The vim integrations — seven `vim-*` plugins, and three that are not about vim mode](../../docs/plugins/vim-integrations.md)