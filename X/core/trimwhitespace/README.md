# trimwhitespace

Strips trailing whitespace from every line, on save.

No key. One command, `trim-whitespace:trim-trailing-whitespace`, so you can see
the hook ran.

It pulls the cursor back when it has to, which is the only interesting part:
trimming a line you were standing at the end of would otherwise leave you past
the text.

A single file, `trimwhitespace.lua`.

**Full page:** [trimwhitespace](../../../docs/plugins/trimwhitespace.md) — when
it runs, the Markdown caveat, and the one gap worth knowing about
