# Introduction to cdin-x

`cdin-x` is the official extension ecosystem for the CDIN text editor.

## Philosophy

Anything that can be isolated from the editor core should be an extension: Git tools,
LSP clients, language syntax, formatters, debuggers, UI tools, themes, and future
integrations.

## Repository architecture

```text
core/       manager, loader, config, manifest, command API
X/          official extension catalog
registry/   generated catalog index
templates/  plugin scaffolds
scripts/    development helpers
docs/       architecture/API/development documentation
```

## Runtime boundary

```text
CDIN installation
  data/core/x/       cdin-x runtime
  data/X/core/       mandatory extensions

User data
  extensions/        installed optional extensions
  registry/cdin-x/   cached catalog
  user/init.lua      personal configuration
```

## Essential extensions

`core`, `autocomplete`, `autoreload`, `autoupdate`, `projectsearch`, `session`,
`trimwhitespace`, `vim`, `treeview`, `tab`, and `window` are currently shipped as
non-removable built-ins.

## Plugin manager

The Vim `m` menu opens the normal CDIN menu. Its **Extensions** entry delegates to the
CDIN-X manager, which owns search, README display, installation, enable/disable,
uninstallation, local installation, and catalog refresh.

## Contribution

Create a plugin locally first. Once it is stable, place it under `X/<category>/` and
open a PR to the `cdin-x` repository.
