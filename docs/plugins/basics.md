# basics

Two small conveniences with nothing in common: one watches the disk, one changes
what gets saved. They are two features of one package so a user who wants neither
pays for neither.

| feature | what it does | commands | keys |
| --- | --- | --- | --- |
| `autoreload` | reload a document when the file changes underneath it | none | none |
| `trimwhitespace` | strip trailing whitespace before every save | `trim-whitespace:trim-trailing-whitespace` | none |

Neither has a key. `autoreload` is a background watch with nothing to press, and
`trimwhitespace`'s one command exists mostly so you can see that the hook ran.

## The rule to know before you install autoreload

**It replaces the buffer with what is on disk. Your unsaved changes go.**

The reload is a document edit, not a merge. So:

- Do not have unsaved changes in a file that something else is about to rewrite.
- If you are editing a generated file, leave it off.
- If you are reviewing a diff another process is changing underneath you, leave
  it off.

This is not a limitation that could be fixed by merging; it is what "reload"
means. The feature is worth having when your files change underneath you
repeatedly, and not worth having when they do not — which is why it is a feature
you can switch off rather than something a build turns on.

## What autoreload does

```text
every config.project_scan_rate seconds:
    for each open document:
        if the file's mtime differs from what we last saw:
            re-read it, restore the cursor, mark it clean
```

`config.project_scan_rate` is the same interval the project scanner uses — short
while a scan is running, longer when idle. So autoreload checks often when
something else is already watching the disk and slowly when nothing is. It reuses
the number rather than inventing a second one.

**It strips carriage returns and the trailing newline** before inserting, so a
file written with Windows line endings does not gain a stray `\r` on every reload,
and does not gain a blank line at the end on every reload. Repeated reloads are
therefore idempotent, which is the property that makes a background reload safe to
leave on.

**It marks the document clean afterwards.** The file on disk *is* the buffer, so
leaving it dirty would produce a prompt asking whether to overwrite a file you did
not change.

**The timestamps are weak keys.** Closing a tab lets its entry go. Without that, a
long session would accumulate one entry per file ever opened, which is a leak that
would never announce itself.

**The loop yields; it never blocks a frame.** `coroutine.yield` hands control back
to the frame loop, so a slow filesystem costs you a frame and not the editor.

## What trimwhitespace does

On save, for every line: if the text ends in whitespace, remove it. That is the
entire feature.

**It fixes the cursor when it has to.** If the cursor was in the trailing
whitespace it is about to delete — which happens whenever you were at the end of a
line — it is pulled back to the new end of the line first. Without that, trimming
a line you were standing at the end of would leave the cursor past the text, and
the next thing you typed would land somewhere you did not expect.

That is the whole of the interesting logic, and it is four lines. Everything else
here is about when it runs.

## Why both are hooks rather than wrappers

`table.insert(Doc._before_save, trim_trailing_whitespace)` and
`table.insert(Doc._after_load, update_time)`.

The alternative is wrapping `Doc.save` and `Doc.load`, which would mean
intercepting methods on a class every other package also touches, restoring them
on unload, and hoping nobody else wrapped it first. A list of callbacks the class
calls itself is none of those problems. The features add a function to a list and
the document does the rest.

**The thread is the awkward one.** `core.add_thread` has no cancel, so
autoreload's loop is stopped by being *told* to stop: a `running` flag it checks
every pass. That is why `disable()` sets a variable rather than reaching for the
coroutine.

## Switching features off

```lua
return {
  features = {
    basics = { autoreload = false },
  },
}
```

`<kbd>F</kbd>` under `basics` in the extension panel does the same thing, without
a restart.

**Both features now really do come back off.** That was not true when they were
separate plugins: `unload()` on both was empty, so disabling either left its
thread running or its hook in `Doc._before_save`, and every save kept trimming.
The fix was to keep a reference to the function and remove it from the list by
identity, and to give the thread a flag — small, but the reason this page can make
the claim at all.

## A file whose trailing whitespace is significant gets changed

That is what you asked for by switching `trimwhitespace` on. Some formats —
Markdown's two-space line break, for one — use trailing whitespace on purpose,
and this will remove it. Worth knowing before you turn it on in a Markdown-heavy
repository.

## Files

```text
init.lua                      package lifecycle only
features/autoreload.lua       the thread, and the two document hooks
features/trimwhitespace.lua   the command, and the one save hook
```