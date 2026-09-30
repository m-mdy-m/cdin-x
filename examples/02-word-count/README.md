# word-count

Counts the words in the active document, shows it in the status bar, and
reports the details into the log on demand.

## Try it

```sh
cd <site>
cp -r /path/to/examples/02-word-count word-count
```

<kbd>Shift</kbd>+<kbd>M</kbd> → **Install Local** → `<site>/word-count`.

Open a file. A pill appears at the left of the status bar. It disappears when
no document has focus, because the provider returns `nil` rather than a zero.

<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>W</kbd>, or `word-count:report` in the
command palette, logs the full count.

## What to notice

**The document comes from the host.** `core.active_docview()` returns the
focused document view, or nothing. There is no global "current document" to
reach into and no way to guess which of several you meant.

**The status bar has a registry.** `core.register_status_pill(key, provider)`
takes a *provider*, not a value — the status bar calls it on every draw and
draws whatever `(text, background, foreground)` it returns. Returning `nil`
draws nothing, which is how a plugin says "I have nothing to say right now"
without a flag for it.

**The provider is cached, and the comment says why.** A pill is asked for on
every frame; counting words in a large file every frame is a real cost. The
cache is keyed on the document and its undo index — the cheapest change signal
the host offers today, and an implementation detail rather than a promise.
That is worth saying out loud in a plugin rather than depending on quietly.

**The predicate is a string.** `command.add("core.views.docview", …)` means
*only in a document view*, and it costs nothing to get right.

## Files

| file | holds |
| --- | --- |
| `init.lua` | the manifest, measuring, the status pill, `init` / `unload` |
| `commands.lua` | `word-count:report` |

Next: [03-vim-word-count](../03-vim-word-count) puts the same count behind a
`:command` and a vim key.
