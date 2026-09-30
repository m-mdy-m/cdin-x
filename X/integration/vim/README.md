# vim

Vim mode, seen from the outside.

| directory | adds to vim |
| --- | --- |
| `vim-git/` | git commands, and a menu section for them |
| `vim-menu/` | the <kbd>m</kbd> menu, and vim's own sections |
| `vim-plugin-manager/` | the extension manager, reachable from vim |
| `vim-search/` | `/ n N *` over the search plugin |
| `vim-tab/` | `:tabnew`… and `gt` / `gT` |
| `vim-treeview/` | `:tree`, and the project tree |
| `vim-window/` | `:split`…, <kbd>Ctrl</kbd>+<kbd>W</kbd> and <kbd>Tab</kbd> |

None of them patch vim mode. Each claims one of the seams
`X.core.vim.registry` offers, and vim core is left knowing nothing about tabs,
trees, search, or git — so removing any of these leaves no half-wired command
behind.

`vim-menu` is the one to declare a dependency on when you extend `vim.main`.
See [the note one directory up](../README.md).

The seams, with a worked example:
[docs/extending-vim.md](../../../docs/extending-vim.md).
