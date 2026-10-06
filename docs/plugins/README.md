# Plugins

One page per package: what it does, what you press, and how it works.

Read the page for the thing you're about to use. The "how it works" half is
there for when something does something you didn't expect and you'd rather know
why than guess.

## The packages

One subject each. Install from the manager and they work on their own.

| page | package | what it is |
| --- | --- | --- |
| [manager](manager.md) | the panel | the extension panel — **in every build**, like vim |
| [vim](vim.md) | `vim` | modal editing and the `:` command line |
| [search](search.md) | `search` | find, replace, and search across the project |
| [menu](menu.md) | `menu` | the generic searchable menu other packages build on |
| [git](git.md) | `git` | running git, and repository status |
| [treeview](treeview.md) | `treeview` | the project file tree |
| [workspace](workspace.md) | `workspace` | tabs, window splits, and what survives a restart |
| [launcher](launcher.md) | `launcher` | the palette, file finder, and config shortcuts |
| [complete](complete.md) | `complete` | symbol completion |
| [update](update.md) | `update` | is there a newer cdin |
| [basics](basics.md) | `basics` | pick up external edits, strip trailing whitespace |
| [text-tools](text-tools.md) | `text-tools` | right-to-left text, Arabic shaping, Unicode inspection |
| [themes](themes.md) | `themes` | the bundled themes, and switching between them |

## Two things a package can be made of

A package may be split into **features** — parts you can switch off — and it may
declare **`with` entries** — wiring to a *different* package that runs only while
both are loaded. The pages above use both where it applies, and say so.

| you want to read | because |
| --- | --- |
| [workspace](workspace.md), [basics](basics.md), [text-tools](text-tools.md) | these are feature packages: the page names each feature and what switching it off removes |
| [vim](vim.md), [themes](themes.md), [git](git.md) | these have `with` entries: something here is wired to something there, and only runs when both are loaded |

## Making your own

Separate, because these are for writing rather than using.

| page | for |
| --- | --- |
| [building a feature](../building/a-feature.md) | splitting a package into parts a user can switch off |
| [building a with entry](../building/a-with-entry.md) | connecting two packages that must not know about each other |
| [adding a theme](../building/a-theme.md) | a theme, and where every colour in the editor comes from |
| [adding a syntax definition](../building/a-syntax-definition.md) | highlighting a language |
| [writing a plugin](../writing-a-plugin.md) | the whole shape of a package, before any of the above |

## What every page has

**Keys** are listed the way the editor spells them, so `ctrl+shift+p` here is
the same string you would put in a keymap. A key that is a *list* is a
fallback chain — the commands are tried in order and the first whose predicate
holds runs. That is how <kbd>Ctrl</kbd>+<kbd>D</kbd> belongs to both search and
word-selection without either of them knowing.

**Commands** are the names the palette shows. If a command is not bound to a
key, that is deliberate and the page says so.

**How it works** is the part worth reading when something surprises you. It
tends to explain a rule the package obeys, and the failure the rule exists to
prevent.

## Naming, once

Two package names changed when packages gained a `package.lua`, and the old
names are what a search will still turn up:

| you will find | is now |
| --- | --- |
| `autocomplete` | [`complete`](complete.md) |
| `autoupdate` | [`update`](update.md) |

Their **commands kept their old names** — `autocomplete:complete` and
`autoupdate:check` are spelled exactly as before — because a user's `init.lua`
and a keymap both name them, and renaming those would break working
configuration. Only the package identity moved.

`palette`, `finder` and `modules` are no longer packages either; they are three
features of [`launcher`](launcher.md). `tab`, `window` and `session` are features
of [`workspace`](workspace.md).