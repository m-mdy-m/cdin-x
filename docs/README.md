# Documentation

Six documents, in the order most people need them, plus two directories.

## Using it

**[Getting started](getting-started.md)** — install, first launch, install a
first package, get rid of it again. If you read one page, read that one.

**[Installing packages](installing-plugins.md)** — where a package comes from,
what every item in the manager's menu does, and what to check when one doesn't
appear.

## Using one package

**[plugins/](plugins/)** — one page per package. What it does, what you press,
and how it works. The "how it works" half is there for when something does
something you did not expect, so you can find out why rather than guess.

Start at [the index](plugins/README.md); it says which page is which, and which
pages are *features* of a larger package rather than packages of their own.

## Making one

**[writing-a-plugin.md](writing-a-plugin.md)** — the shape of a package, before
anything else. Short, and everything else sits inside it.

**[building/](building/)** — the things people actually make:

| | |
| --- | --- |
| [a feature](building/a-feature.md) | make part of a package switchable |
| [a with entry](building/a-with-entry.md) | connect two packages that must not know each other, with worked examples |
| [a theme](building/a-theme.md) | every colour the editor has, and what each one is for |
| [a syntax definition](building/a-syntax-definition.md) | highlight a language |

**[extending-vim.md](extending-vim.md)** — the seven seams vim mode offers, and
a worked `with` entry.

**[examples/](../examples)** — three complete packages, smallest first. Copy one
and edit it; that is the intended use.

## Working on this repository

**[CONTRIBUTING.md](../CONTRIBUTING.md)** — what `make validate` enforces and
why, so you can satisfy it without guessing.

**[scripts/README.md](../scripts/README.md)** — the two Python scripts and the
four Lua tools, and what each one refuses to do.

## Elsewhere

cdin's own half is documented in the
[cdin repository](https://github.com/m-mdy-m/cdin), and the part of it that
constrains anything here is
[the extension contract](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md).
Read that before relying on anything this repository's pages don't mention —
in particular, there is no hook or event system, so extending something means
wrapping the function and calling the original.

## The short version

```sh
make link                  # install into the editor's site directory
make validate              # the gate, before every commit
make list                  # what the catalog holds
make bundle BUNDLE=standard DEST=<dir>   # what a cdin build consumes
make install               # copy instead of link
make uninstall             # take it back out
```
