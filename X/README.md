# X

What has not moved into `packages/`. A package lives under
`packages/<domain>/<name>` once it has a `package.lua`, and stays here until
then. Both roots are scanned, so a package is found wherever it is and a tree can
be half-moved.

Installed as `<site>/X/`, and the host puts `<site>/X/?.lua` on `package.path`
*after* its own modules — so a plugin here is required by its path, and cannot
shadow anything of the editor's. A plugin with a `package.lua` is required by its
*name* instead, through cdinx's own searcher, so both spellings work at once and
the move does not have to happen in one step.

## What is left

| directory | holds |
| --- | --- |
| [`core/`](core) | `vim` — the last entry, and the only package big enough that its optional parts are seams rather than features |
| [`optional/`](optional) | empty, kept so a genuinely standalone plugin has a home that says so |
| [`syntax/`](syntax) | language definitions, one file each |

`integration/` is gone. It held eight packages whose only content was wiring
between two other packages: the seven `vim-*` integrations and `git-treeview`.
Those are now `with` entries — files inside one of the two packages, run only
while both are loaded. See [X/core/vim](core/vim) for the seven, and
`packages/vcs/git/with/treeview.lua` for the other.

That is the whole of what `integration/` was for, and `with` is a better answer to
it: a dependency means neither package is usable alone, whereas a seam means each
one keeps working on its own.

`X/manifest.lua` is generated — run `make manifest`. Don't edit it, and don't
require it.

**How to write one of these:** [docs/writing-a-plugin.md](../docs/writing-a-plugin.md).
**Worked examples:** [examples/](../examples).
