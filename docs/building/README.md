# Making things

Three guides, for the three things people make: a plugin that connects two
others, a theme, and a language definition.

Start with [writing a plugin](../writing-a-plugin.md) if you have not — it is
the shape all three sit inside, and it is short.

| you want to | read |
| --- | --- |
| connect two plugins that must not know each other | [an integration](an-integration.md) |
| change how the editor looks | [a theme](a-theme.md) |
| highlight a language | [a syntax definition](a-syntax-definition.md) |

And the two that are mostly reading:

| | |
| --- | --- |
| add `:tabnew` and <kbd>g</kbd><kbd>t</kbd> to vim mode | [extending vim mode](../extending-vim.md) |
| see the whole shape of a plugin | [writing a plugin](../writing-a-plugin.md) |

## The one rule underneath all of it

**A `X/core/` plugin may not depend on another X plugin.**

Not *prefer* to — may not, at all. If two capabilities need to know about each
other, the knowledge goes in `X/integration/<name>/`, which is allowed to
depend on both and declares them.

This is not bureaucracy. A plugin that works until somebody uninstalls the other
one is a plugin with a failure mode nobody can test for, and a catalog you
cannot reason about is a catalog nobody extends. `make validate` fails the
build on a cross-plugin `require` with no declaration behind it.

The corollary, which is the thing people miss: **if you are writing a `core/`
plugin and you feel the need for a sibling, you have either written two plugins
where one belongs, or the dependency belongs in an `integration/`.** Both are
fixes, and the second is usually the right one.

## Where your own work goes

Not in this repository, unless you want it in the catalog for everyone.

Your plugin lives in your own directory, and **Install Local** in the manager
installs it from that path. That is the whole workflow: edit in your checkout,
re-install, see the change. This repository is the catalog, and everything in it
is something the project offers everybody — so read
[CONTRIBUTING.md](../../CONTRIBUTING.md) before adding to it, and expect a
higher bar than "it works for me".
