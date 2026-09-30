# git

Git process discovery, running git, and reading repository status.

It knows nothing about the file tree, vim menus, or any other UI. Those
relationships are integrations: [`git-treeview`](../../integration/git-treeview)
for badges in the tree, [`vim-git`](../../integration/vim/vim-git) for commands and
a menu section.

The status bar reads the result through `core.register_vcs_provider`, so with
no git plugin loaded it simply renders nothing there rather than erroring.

**Full page:** [git — what it does, what you press, and how it works](../../../docs/plugins/git.md)
