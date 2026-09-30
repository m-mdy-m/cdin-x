# autoreload

Picks up files that changed on disk while you have them open. A `git checkout`,
a formatter, another editor, a build step.

No keys, no commands, no badge. It watches, and re-reads.

**The rule to know: it replaces the buffer with what is on disk, so unsaved
changes in that file go.** The reload is an edit, not a merge. Do not install
this if you are editing files that something else is rewriting underneath you.

A single file, `autoreload.lua`.

**Full page:** [autoreload](../../../docs/plugins/autoreload.md) — what it
watches, what it does, and the one gap worth knowing about
