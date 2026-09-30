# autoreload

Picks up files that changed on disk while you have them open.

No keys, no commands, no badge. It watches, and when a file you have open is
modified by something else — a `git checkout`, a formatter, another editor, a
build step — it re-reads the file and puts the cursor back where it was.

## The rule to know before you install it

**It replaces the buffer with what is on disk. Your unsaved changes go.**

The reload is a document edit, not a merge. So:

- Do not have unsaved changes in a file that something else is about to rewrite.
- If you are editing a generated file, leave this off.
- If you are reviewing a diff that another process is changing underneath you,
  leave this off.

This is not a limitation that could be fixed by merging; it is what "reload"
means. The plugin is worth having when your files change underneath you
repeatedly, and not worth having when they do not. That is why it is optional
and why it is off until you install it.

## What it does

```text
every config.project_scan_rate seconds:
    for each open document:
        if the file's mtime differs from what we last saw:
            re-read it, restore the cursor, mark it clean
```

`config.project_scan_rate` is the same interval the project scanner uses —
0.05 while a scan is running, and a longer idle value otherwise. So autoreload
checks often when something else is already watching the disk, and slowly when
nothing is. It reuses the number rather than inventing a second one.

**It strips carriage returns and the trailing newline** before inserting, so a
file written with Windows line endings does not gain a stray `\r` on every
reload, and does not gain a blank line at the end on every reload. Repeated
reloads of the same file are therefore idempotent, which is the property that
makes a background reload safe to leave on.

**It marks the document clean afterwards.** The file on disk *is* the buffer, so
leaving it dirty would produce a prompt asking whether to overwrite a file you
did not change.

**The timestamps are weak keys.** The table mapping document to mtime is a weak
table, so closing a tab lets its entry go. Without that, a long session would
accumulate one entry per file ever opened, which is a leak that would never
announce itself.

## How it works

**It hooks `Doc._after_load` and `Doc._after_save`** to learn a document's mtime
when it opens or when you save it, and runs one `core.add_thread` loop for the
watching. It does not wrap `Doc.save` or `Doc.load` — those are the operations
that would be wrong to intercept, and a list of "after" callbacks is the seam
that does not require replacing anything.

**The loop yields; it never polls in a blocking way.** `coroutine.yield` hands
control back to the frame loop, so a slow filesystem costs you a frame and not
the editor.

## Known gaps

**`unload()` does nothing.** The thread it started is not stopped, and the two
`Doc` callbacks it inserted are not removed. Disabling the plugin therefore
leaves it running. If you disable it and the behaviour does not change, that is
why — and it is worth knowing before you conclude the plugin is broken.

The fix is small: have the loop check a flag the thread closes over, and keep
the function references so `unload` can pull them out of the two lists. It is
recorded here rather than done because it is a change to working code on a
plugin nobody uses much, and that is not a trade to make quietly.
