# Menu core

`menu` is a generic menu primitive. It owns sections, providers, context, ordering,
and presentation. It does not know about Vim, Git, Treeview, search, or the plugin manager.

Other plugins register menus through `X.core.menu.impl` and integrations can compose
those menus without creating feature-to-feature dependencies in core.
