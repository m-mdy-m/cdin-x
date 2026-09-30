# Plugins

One page per plugin: what it does, what you press, and how it works.

Read the page for the thing you're about to use. The "how it works" half is
there for when a plugin does something you didn't expect and you'd rather know
why than guess.

## The capabilities

One thing each. Install from the manager and they work on their own.

| page | plugin | what it is |
| --- | --- | --- |
| [vim](vim.md) | `vim` | modal editing and the `:` command line — **always loaded** |
| [search](search.md) | `search` | find, replace, and search across the project |
| [menu](menu.md) | `menu` | the generic searchable menu other plugins build on |
| [git](git.md) | `git` | running git, and repository status |
| [treeview](treeview.md) | `treeview` | the project file tree |
| [tab](tab.md) | `tab` | tabs |
| [window](window.md) | `window` | splits, focus, layout |
| [finder](finder.md) | `finder` | open a file or folder by name |
| [palette](palette.md) | `palette` | run any command by name |
| [session](session.md) | `session` | what survives a restart |
| [autocomplete](autocomplete.md) | `autocomplete` | symbol completion |
| [modules](modules.md) | `modules` | reload a module, open your config |
| [autoupdate](autoupdate.md) | `autoupdate` | is there a newer cdin |
| [autoreload](autoreload.md) | `autoreload` | pick up files changed outside the editor |
| [trimwhitespace](trimwhitespace.md) | `trimwhitespace` | strip trailing whitespace on save |
| [optional](optional.md) | three | RTL, theme switching, Unicode inspection |

## The integrations

Thin plugins that connect two capabilities that must not know about each
other. Installing one is what gives you a feature; the capability itself does
nothing without it.

| page | what you get |
| --- | --- |
| [vim integrations](vim-integrations.md) | every `vim-*` integration, and what each one adds to vim mode |

## Making your own

Separate, because these are for writing rather than using.

| page | for |
| --- | --- |
| [building an integration](../building/an-integration.md) | connecting two plugins — with `git` and `window` worked through end to end |
| [adding a theme](../building/a-theme.md) | a theme, and where every colour in the editor comes from |
| [adding a syntax definition](../building/a-syntax-definition.md) | highlighting a language |
| [writing a plugin](../writing-a-plugin.md) | the whole shape of a plugin, before any of the above |

## What every page has

**Keys** are listed the way the editor spells them, so `ctrl+shift+p` here is
the same string you would put in a keymap. A key that is a *list* is a
fallback chain — the commands are tried in order and the first whose predicate
holds runs. That is how <kbd>Ctrl</kbd>+<kbd>D</kbd> belongs to both search and
word-selection without either of them knowing.

**Commands** are the names the palette shows. If a command is not bound to a
key, that is deliberate and the page says so.

**How it works** is the part worth reading when something surprises you. It
tends to explain a rule the plugin obeys, and the failure the rule exists to
prevent.
