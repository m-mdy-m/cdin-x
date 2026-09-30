# Getting started

Two repositories, one editor.

[cdin](https://github.com/m-mdy-m/cdin) is the editor: the window, the
renderer, the text pipeline, the document, the command and key registries. It
knows nothing about plugins, and a checkout of it builds and runs on its own —
`make bin` there needs nothing from this repository.

This one is everything the editor isn't. The command palette, the file finder,
the project tree, tabs, search, git, the themes, the fonts, and the vim mode
you're probably using right now.

## Install

```sh
git clone https://github.com/m-mdy-m/cdin-x.git
cd cdin-x
make link
```

That links three directories into cdin's **site directory** and writes nothing
else. `make install` copies the same three instead, which is what you want if
you don't plan to edit this checkout. `make uninstall` takes them back out; your
cdin installation is not touched by any of the three.

The site directory is `<data_home>/cdin/site`, where `data_home` is
`$XDG_DATA_HOME` or `~/.local/share` on Linux and macOS, and `%LOCALAPPDATA%`
(then `%APPDATA%`, then `%USERPROFILE%\AppData\Local`) on Windows. If you
renamed the directory, tell the installer too:

```sh
make link SITE_NAME=extensions        # just the name
make link SITE=/somewhere/else         # or a full path
```

## What you get

Three directories land in the site:

```text
<site>/cdinx/            the manager — the code that installs and loads plugins
<site>/X/                the plugins themselves
<site>/plugins/cdin-x/   one file, the entry point cdin's loader finds
```

A fourth thing is already there and does not come from here: **vim**. It is the
one plugin a cdin build cannot start without, so it is bundled into the editor
itself rather than installed next to everything else. It's already loaded by the
time any site plugin runs.

That's the whole split. cdin owns the editor and the mandatory set; this
repository owns the rest, and nothing in a cdin checkout ever points at it.

## First launch

Start cdin and press <kbd>shift</kbd>+<kbd>M</kbd>. That's the manager.

<kbd>J</kbd> and <kbd>K</kbd> move, <kbd>Space</kbd> toggles, <kbd>Enter</kbd>
opens the plugin, <kbd>U</kbd> uninstalls, <kbd>R</kbd> opens its README,
<kbd>Ctrl</kbd>+<kbd>R</kbd> refreshes the catalog, <kbd>Esc</kbd> closes.

If you'd rather not learn a second set of keys, the same panel is a vim menu
section: press <kbd>m</kbd>, then <kbd>X</kbd>. And if the command palette is
what you live in, `cdin-x:menu` is in there under its own name.

## Your first plugin

From the manager, pick **Extensions** and you'll see everything in the
catalog — the treeview, the finders, search, the themes beyond the default.
Pick one, hit <kbd>Space</kbd>, and it's installed and loaded. No restart.

This is the part that surprises people: after this one-time `make link`, you
never come back to this repository to install anything. The manager talks to a
catalog over the network, and cdin-x is what puts that catalog there.

Which is worth reading about next:

- **[installing-plugins.md](installing-plugins.md)** — where plugins come from,
  what the manager's menu does, and what to do when one doesn't show up.
- **[writing-a-plugin.md](writing-a-plugin.md)** — writing your own. You don't
  do it here; you do it in your own directory and install it from there.
- **[extending-vim.md](extending-vim.md)** — the seven seams vim mode offers,
  if that's the part you're after.

## Getting rid of it

```sh
make uninstall
```

The editor keeps working. It loses the palette, the finders, and everything
else from here, and keeps the vim mode it was built with — which is the honest
test of the split: a cdin with no cdin-x on the machine is still a cdin.

## If something doesn't appear

In rough order of likelihood:

**The site directory isn't where the editor is looking.** Run
`make link` and read the `site :` line it prints, then compare against what
cdin resolved. The name is cdin's to choose — see
[configuration.md](https://github.com/m-mdy-m/cdin/blob/main/docs/guides/configuration.md)
in the cdin repository, or your `~/.config/cdin/user/init.lua` if you've
changed it.

**A failing bundled plugin is reported, not fatal.** cdin always starts. If
something in here threw during load, the error is in the log — <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd>
opens it, and so does the `core:open-log` command.

**You set `config.plugins = false`.** That means *no site plugins*, which
includes this. The bundled set is unaffected — that's the whole reason
`--no-plugins` can't turn vim off.
