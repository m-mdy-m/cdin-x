# Making things

Four guides, for the four things people make: a package, a switchable part of
one, wiring between two, a theme, and a language definition.

Start with [writing a plugin](../writing-a-plugin.md) if you have not — it is the
shape all of them sit inside, and it is short.

| you want to | read |
| --- | --- |
| see the whole shape of a package | [writing a plugin](../writing-a-plugin.md) |
| make part of a package switchable | [a feature](a-feature.md) |
| connect two packages that must not know each other | [a with entry](a-with-entry.md) |
| change how the editor looks | [a theme](a-theme.md) |
| highlight a language | [a syntax definition](a-syntax-definition.md) |

And the one that is mostly reading:

| | |
| --- | --- |
| add `:tabnew` and <kbd>g</kbd><kbd>t</kbd> to vim mode | [extending vim mode](../extending-vim.md) |

## The one rule underneath all of it

**A package may not depend on another package.**

Not *prefer* to — may not, at all. If two packages need to know about each other,
the knowledge goes in a **`with` entry**, which is allowed to reach both and
declares them.

This is not bureaucracy. A package that works until somebody uninstalls the other
one is a package with a failure mode nobody can test for, and a catalog you cannot
reason about is a catalog nobody extends. `make validate` fails the build on a
`with` file that reaches a package its own manifest key did not name.

The corollary, which is the thing people miss: **if you are writing a package and
you feel the need for a sibling, you have either written two packages where one
belongs, or the connection belongs in a `with` entry.** Both are fixes, and the
second is usually the right one.

## The three kinds of "optional"

They are different mechanisms and this is the most common confusion:

| you want to | use | declared as |
| --- | --- | --- |
| a package that is not installed | a separate package | nothing — just don't depend on it |
| part of a package off | a **feature** | `features = { … }`, in the same `package.lua` |
| two packages talking | a **`with` entry** | `with = { <partner> = "<path>" }` |

And the one that is *not* a mechanism at all: a package whose `min_cdin_version`
the host does not satisfy is refused, not silently skipped. That is a different
kind of decision from all three, and it is the only one that stops a load.

## Where your own work goes

Not in this repository, unless you want it in the catalog for everyone.

Your package lives in your own directory, and **Install Local** in the manager
installs it from that path. That is the whole workflow: edit in your checkout,
re-install, see the change. This repository is the catalog, and everything in it
is something the project offers everybody — so read
[CONTRIBUTING.md](../../CONTRIBUTING.md) before adding to it, and expect a
higher bar than "it works for me".