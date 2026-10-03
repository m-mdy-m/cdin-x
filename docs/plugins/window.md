# window

Splits, focus movement, and resizing.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>\</kbd> | `window:split` — split horizontally |
| <kbd>Ctrl</kbd>+<kbd>\</kbd> | `window:vsplit` — split vertically |
| <kbd>Alt</kbd>+<kbd>W</kbd> | next pane (wraps) |
| <kbd>Alt</kbd>+<kbd>P</kbd> | back to the pane you were in before this one |

<kbd>Alt</kbd>+<kbd>P</kbd> is `window:focus-prev-window`, which jumps to
`core.last_active_view`. It is **not** the order-based `window:focus-prev`, which
has no key at all — two different meanings of "previous", kept as two commands.

Eleven more commands have no key, deliberately: `window:new`, `window:vnew`,
`window:split-open`, `window:vsplit-open`, `window:close-force`,
`window:close-all-views`, `window:focus-prev`, `window:focus-first`,
`window:focus-last`, `window:maximize-width`, `window:maximize-height`.
| <kbd>Alt</kbd>+<kbd>H</kbd> <kbd>J</kbd> <kbd>K</kbd> <kbd>L</kbd> | left, down, up, right |
| <kbd>Alt</kbd>+<kbd>←</kbd> / <kbd>→</kbd> | narrower / wider |
| <kbd>Alt</kbd>+<kbd>↑</kbd> / <kbd>↓</kbd> | shorter / taller |
| <kbd>Alt</kbd>+<kbd>=</kbd> | equalize |
| <kbd>Alt</kbd>+<kbd>O</kbd> | close every other pane |
| <kbd>Alt</kbd>+<kbd>C</kbd> | close this pane |

**The arrow keys are named, not drawn.** In a keymap the four resizing strokes
are `alt+left`, `alt+right`, `alt+up` and `alt+down` — words, not `alt+←`:

```lua
-- ~/.config/cdin/user/init.lua
keymap.add { ["alt+left"] = "window:decrease-width" }
```

That is worth knowing before you rebind one and nothing happens, and it is the
same for the two splits: `ctrl+\` and `ctrl+shift+\`, written with a literal
backslash.

The full set is `window:split`, `:vsplit`, `:vnew`, `:new`, `:split-open`,
`:vsplit-open`, `:close`, `:close-all-views`, `:close-force`, `:only`,
`:equalize`, `:focus-next`, `:focus-prev`, `:focus-first`, `:focus-last`,
`:focus-up`, `:focus-down`, `:focus-left`, `:focus-right`,
`:focus-prev-window`, `:increase-width`, `:decrease-width`,
`:increase-height`, `:decrease-height`, `:maximize-width`,
`:maximize-height`.

`window:split-open` and `window:vsplit-open` take a path, so they open a file
in a new pane rather than an empty one.

## In vim mode

With `vim-window` installed, the <kbd>Ctrl</kbd>+<kbd>W</kbd> prefix and its
ex-command twin:

| keys | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>v</kbd> / <kbd>s</kbd> | vertical / horizontal split |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>o</kbd> | only this pane |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>c</kbd> or <kbd>q</kbd> | close |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>n</kbd> / <kbd>w</kbd> | next pane |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>p</kbd> | previous pane |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd> | left, down, up, right |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>=</kbd> <kbd>&gt;</kbd> <kbd>&lt;</kbd> | equalize, wider, narrower |
| <kbd>Tab</kbd> | next pane |
| `:split` / `:sp`, `:vsplit` / `:vs`, `:vnew` | the same, from `:` |
| `:close` / `:clo`, `:only` / `:on` | close, only |
| `:wincmd {c}` | any of the above, as a command |

`:wincmd` is vim's own ex-mode syntax, and it takes the same characters as the
<kbd>Ctrl</kbd>+<kbd>W</kbd> prefix because both resolve through the same table.
That is a genuine vim feature rather than a convenience here, and it is
implemented as one: the character maps to a *cdin command name*, and neither
vim core nor ex mode knows what `v` or `o` mean.

<kbd>Tab</kbd> moving to the next pane is the one that is not vim. It is what
<kbd>Tab</kbd> does in every other editor, and it is registered through the same
seam as the rest — consulted only after vim's own keys decline, so it cannot
shadow one.

## How it works

```text
window/manager.lua          the public surface
window/manager/ops.lua      split, close, resize
window/manager/focus.lua    moving between panes
window/manager/context.lua  which pane, and what is in it
window/manager/teardown.lua closing, without the prompt
```

**A split is a view in the root tree, not a window in the OS sense.** The
renderer has one window; a split is the root view's node tree gaining a
sibling. That is why `window:close` on the last pane does not close the
application — and the guard for it is in `manager/ops.lua`, not `teardown.lua`:
it counts the leaves and logs `window: only one window open`.

**`window:close` and `window:close-force` are different code paths, not the
same path with a flag.** `close` delegates to the host's
`node:close_active_view`, which is what prompts about unsaved changes.
`close-force` calls this plugin's own `teardown.close_active_view`, which does
not prompt at all.

**`window:close-all-views` discards unsaved changes and never asks.** The
command's own comment claims "the caller confirms first"; no caller does. It
loops up to a thousand times, installs the host's empty view at the end, and
garbage-collects unreferenced documents. `window:close-all-views` is not a key,
which is the only thing keeping that survivable.

**Focus is geometric, and it does not wrap.** `focus-left` from the leftmost
pane does nothing, and neither does `focus-right` from the rightmost — adjacency
needs the panes to overlap on the cross axis by half, with a two-cell tolerance.
Only `focus-next` and `focus-prev` wrap, because they walk the leaf list by
index. `focus-prev` and `focus-prev-window` are different commands for a real
reason: the first is order-based, the second jumps to `core.last_active_view`.

**`maximize-width` and `maximize-height` are not `only`.** They push the divider
to `0.9` (or `0.1`), so the other pane keeps a tenth of the axis — visible, not
collapsed. They are also the only resize paths that **emit no event**: every
other one calls the same `emit` that `context.lua` implements as
`core.redraw = true`, so the two arguments are discarded and nothing is actually
listened to anyway.

**The <kbd>Ctrl</kbd>+<kbd>W</kbd> table is a cdin command name per character.**
Not a function. So a keymap entry in `~/.config/cdin/user/init.lua` can rebind
<kbd>Ctrl</kbd>+<kbd>W</kbd> <kbd>v</kbd> to something else without the plugin
knowing, and the same table serves both the prefix and `:wincmd` because there
is only one table.

## Files

| file | holds |
| --- | --- |
| `manager.lua` | the public surface |
| `manager/ops.lua` | split, close, resize |
| `manager/focus.lua` | focus movement |
| `manager/context.lua` | which pane, and what is in it |
| `manager/teardown.lua` | closing without a prompt |
