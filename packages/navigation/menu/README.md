# menu

A generic menu: sections, providers, context, ordering, presentation.

It knows nothing about vim, git, the tree, search, or the manager. Other
plugins register their own sections; integrations compose them. That is the
whole reason it's a `core/` plugin rather than a utility each of them grew.

`menu.extend(name, section, …)` **asserts** that the menu exists, so an
integration extending a menu has to declare whichever integration *defines* it,
not merely the plugin that owns menus. See
[the note in `../../integration/`](../../integration/README.md) — it is a
load-order trap with a very bad failure shape.

**Full page:** [menu — what it does, what you press, and how it works](../../../docs/plugins/menu.md)
