# trimwhitespace

Strips trailing whitespace from every line, on save.

No key. It registers one command and a save hook, and the command exists mostly
so you can see that the hook ran.

| command | does |
| --- | --- |
| `trim-whitespace:trim-trailing-whitespace` | trim the current document now |

## What it does

On save, for every line: if the text ends in whitespace, remove it. That is the
entire feature.

**It fixes the cursor when it has to.** If the cursor was in the trailing
whitespace it is about to delete — which happens whenever you were at the end
of a line — it is pulled back to the new end of the line first. Without that,
trimming a line you were standing at the end of would leave the cursor past the
text, and the next thing you typed would land somewhere you did not expect.

That is the whole of the interesting logic, and it is four lines. Everything
else in this page is about when it runs.

## Why it is a hook and not a `save` wrapper

`table.insert(Doc._before_save, trim_trailing_whitespace)`.

The alternative is wrapping `Doc.save`, which would mean: intercepting a method
on a class every other plugin also touches, restoring it on unload, and hoping
nobody else wrapped it first. A list of callbacks the class calls itself is
none of those problems. `trimwhitespace` adds a function to a list and the
document does the rest.

## Known gaps

**`unload()` does nothing**, so the callback stays in `Doc._before_save` after
the plugin is disabled. Every save keeps trimming.

It is the same shape of gap as [autoreload](autoreload.md)'s, and for the same
reason it is written down rather than quietly fixed: the fix is to keep a
reference to the function and remove it from the list in `unload`, which is a
two-line change to a plugin that is otherwise correct. Worth doing; not worth
doing as a drive-by in someone else's work.

**A file whose trailing whitespace is significant gets changed.** That is what
you asked for by installing it. Some formats — Markdown's two-space line break,
for one — use trailing whitespace on purpose, and this plugin will remove it.
That is worth knowing before you install it in a Markdown-heavy repository.

## Files

Single file, `trimwhitespace.lua`.
