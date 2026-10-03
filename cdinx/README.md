# cdinx

The manager: what finds plugins, what installs them, what loads them, and what
the <kbd>Shift</kbd>+<kbd>M</kbd> panel draws.

```text
cdinx/init.lua          bootstrap — publishes itself on core.cdinx
cdinx/command.lua       the commands and the menu
cdinx/panel/            the panel itself, six files
cdinx/config.lua        paths, read from the host's config
cdinx/manifest.lua      the manifest reader
cdinx/manager/          catalog, fetch, deps, lifecycle, loader, registry, runtime, state
```

It is installed at `<site>/cdinx/` and reaches every module by its path from
here. It knows nothing about where cdin is installed, and the one thing it
takes from the host is `config.site_path()` — the editor's own resolver, rather
than a path computed here, so a user who renames the site directory renames it
for both halves at once.

The catalog merges three roots — this repository's `X/` (builtin), the user's
own store (installed), and the cached catalog index of the registry — with later sources
winning. The full table of what that means in practice is in
[docs/installing-plugins.md](../docs/installing-plugins.md).
