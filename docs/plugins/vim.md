# vim

Modal editing, and the `:` command line.

This is the only plugin marked `essential`. A cdin build copies it in, because
an editor with no other modal editing isn't an editor, and it is loaded whether
or not you install anything else. <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd>
turns it off if you would rather type normally.

## Turning it on and off

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd> | `vim:toggle-mode` |

It is **on by default.** The choice is not remembered across restarts yet, so
if you turn it off, turn it back on next time — or set it in your
`~/.config/cdin/user/init.lua`, which is what the `vim_mode_enabled` option is
for.

## Modes

| mode | what you are doing | how you leave it |
| --- | --- | --- |
| **normal** | moving and running commands | <kbd>i</kbd> to insert, <kbd>v</kbd> for visual |
| **insert** | typing | <kbd>Esc</kbd> |
| **visual** | selecting | <kbd>Esc</kbd> |
| **command** | after `:` | <kbd>Esc</kbd>, or running the command |

The mode is shown as a coloured pill at the left of the status bar, and it goes
through normal → insert → visual as you would expect. Pressing <kbd>Esc</kbd>
in insert mode returns to normal, which is the single most important habit in
the whole thing.

## Moving

Normal mode. These eight are the motion set, and they are declared as data in
`vimode/motions.lua` — a key and the cdin command it runs, in normal mode and
in visual mode:

| key | normal | visual |
| --- | --- | --- |
| <kbd>h</kbd> <kbd>l</kbd> | one character left / right | select to there |
| <kbd>j</kbd> <kbd>k</kbd> | one line down / up | select to there |
| <kbd>w</kbd> <kbd>e</kbd> | next word end | select to there |
| <kbd>b</kbd> | previous word start | select to there |
| <kbd>0</kbd> | start of line | — |
| <kbd>$</kbd> | end of line | — |
| <kbd>^</kbd> | first non-blank of the line | — |
| <kbd>gg</kbd> / <kbd>G</kbd> | top / bottom of the file | — |

**There is no page-scrolling movement.** No <kbd>Ctrl</kbd>+<kbd>U</kbd>, no
<kbd>Ctrl</kbd>+<kbd>D</kbd>, no <kbd>Ctrl</kbd>+<kbd>F</kbd>, no
<kbd>Ctrl</kbd>+<kbd>B</kbd>. The status bar shows a scroll percentage, and the
arrow keys move a line.

Which is not an argument against binding them yourself. The motions are ordinary
cdin commands, so a keymap in your `init.lua` is enough:

```lua
-- ~/.config/cdin/user/init.lua
keymap.add {
  ["ctrl+u"] = "doc:move-to-previous-line",
  ["ctrl+d"] = "doc:move-to-next-line",
}
```

That moves a line, not a page, because the underlying commands move a line.
Page movement would need a command that does it, and there is not one — which is
the honest limit of this arrangement: a keymap can only reach what the runtime
already has.

## Editing

| key | does |
| --- | --- |
| <kbd>i</kbd> / <kbd>I</kbd> | insert at the cursor / start of line |
| <kbd>a</kbd> / <kbd>A</kbd> | insert after the cursor / end of line |
| <kbd>o</kbd> / <kbd>O</kbd> | open a line below / above, and insert |
| <kbd>x</kbd> | cut the character under the cursor |
| <kbd>dd</kbd> | delete the line |
| <kbd>cc</kbd> | delete the line, and insert |
| <kbd>yy</kbd> | yank the line |
| <kbd>p</kbd> | paste |
| <kbd>u</kbd> | undo |
| <kbd>r</kbd> | redo |
| <kbd>D</kbd> | cut to the end of the line |
| <kbd>J</kbd> | join with the next line |
| <kbd>v</kbd> | visual mode, and out again |
| <kbd>d</kbd> <kbd>x</kbd> in visual | cut the selection |
| <kbd>y</kbd> in visual | copy it |
| <kbd>&gt;</kbd> / <kbd>&lt;</kbd> in visual | indent / unindent it |

**`r` is redo here, not replace.** That is a deliberate departure from vim, where
<kbd>r</kbd> replaces one character and redo is <kbd>Ctrl</kbd>+<kbd>R</kbd>. It
is one of two, and the other is undo's natural neighbour. It is called out here
because it is exactly the kind of thing you discover by pressing the key and
being surprised.

**There is no <kbd>.</kbd> to repeat the last change.** You will want it, and
it is not here. A number typed before a command is buffered, but the buffer is
only consumed by <kbd>g</kbd><kbd>t</kbd> and <kbd>g</kbd><kbd>T</kbd> — so
<kbd>3</kbd><kbd>g</kbd><kbd>t</kbd> goes to the third tab, and
<kbd>3</kbd><kbd>x</kbd> cuts one character, not three.

## The `:` line

<kbd>Esc</kbd> then <kbd>:</kbd>, or `vim:ex-open`. Arrow keys walk the
history; <kbd>Tab</kbd> completes paths and command names. <kbd>Esc</kbd> backs
out.

These are vim's own, and they are always available:

| command | does |
| --- | --- |
| `:w` `:w!` | save |
| `:wa` | save everything |
| `:q` | close this view |
| `:q!` | close without asking |
| `:qa` / `:qall` | close everything |
| `:qa!` | quit, discarding unsaved changes |
| `:wq` / `:x` | save and close |
| `:wqa` / `:wqall` / `:xa` | save everything and quit |
| `:e path` | open a file |
| `:new path` | open a file, creating it if absent |
| `:ls` | list what is open |
| `:pwd` | the working directory |
| `:cd path` | change directory |
| `:mkdir path` | make a directory |
| `:rm path` | remove a file |
| `:rename old new` | rename, and repoint any open document |
| `:copy src dst` / `:move src dst` | copy or move a file |
| `:wincmd {c}` | the same characters as <kbd>Ctrl</kbd>+<kbd>W</kbd> — see [window](window.md) |
| `:help` | the in-editor key reference |
| `:!cmd` | run a shell command |

`:help` is worth knowing about. It is not the same text as this page — it is
every ex-command registered right now, including the ones your installed
integrations added, which is why it is generated rather than written down.

## Shell

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>;</kbd> | `vim-shell:open-terminal` — a real terminal window |

And through the palette:

| command | does |
| --- | --- |
| `vim-shell:run-custom` | prompt for a command and run it |
| `vim-shell:make` | `make` |
| `vim-shell:make-test` | `make test` |
| `vim-shell:use-cmd` | interactive shells open cmd.exe |
| `vim-shell:use-powershell` | …PowerShell 5 |
| `vim-shell:use-pwsh` | …PowerShell 7+ |

Output goes to a scratch buffer rather than to a terminal you have to switch
windows to. The choice of interactive shell is remembered in
`config.shell_win`.

## What vim mode deliberately does not know

Tabs. The file tree. Search. Git. Splits. The extension manager. The menu.

This is not an omission, and it is the design decision the whole plugin rests
on. If vim mode had its own `:tabnew`, then uninstalling the tab plugin would
leave a `:tabnew` that quietly did nothing — and you would have no way to tell
that from a broken one. So vim mode offers **seams** instead, and
[`X/integration/vim/`](../../X/integration/vim) is where those get filled.

Press <kbd>M</kbd> for the extension manager or <kbd>m</kbd> for the menu, and
neither of those keys is in vim core either. They come from integrations that
register them. If you press <kbd>m</kbd> and nothing happens, `vim-menu` is not
installed.

**What each installed integration adds:** [vim-integrations.md](vim-integrations.md).

## How it works

Four pieces, and the seams are the interesting one.

```text
vim/keymap.lua        Ctrl+Alt+V, the mode toggle
vim/vimode/           modes, keys, motions, the status pill
vim/ex/               the : line — tokenizer, history, completion, the command set
vim/shell/            :!cmd, the scratch buffer, the terminal window
vim/registry.lua      the seven seams
vim/api.lua           an older spelling of the registry, kept working
```

**A key is looked up in this order.** Vim's own keys first, and only if they
decline does the registry get asked. That ordering is what makes it safe for
an integration to claim <kbd>m</kbd> or <kbd>M</kbd>: it can add a key, but it
cannot shadow one vim already handles.

**Modes are the state, not the views.** `vimode/mode.lua` holds normal /
insert / visual and nothing about layout. The status pill reads it. That is why
the pill is registered through `core.register_status_pill` rather than drawn by
vim mode itself — the status bar owns its own drawing and offers a seam.

**The ex command set is a registry, not a table.** `ex/commands.lua`
registers its commands through the same `registry.register_command` that
integrations use, which is why `:tabnew` appears in `:help` and in completion
only when the tab plugin is actually installed. The registry collects every
distinct `help` string and prints them in registration order.

**Essential means self-contained.** The bundler copies this plugin *alone* into
a build, so every `require "X.…"` inside it resolves within its own subtree.
`make validate` checks that, and there is no other way to catch it that isn't a
built binary. The cost of that rule is exactly the seam design above: vim
cannot reach for a sibling, so it has to offer something instead.

## Extending it

[docs/extending-vim.md](../extending-vim.md) — the seven seams, with a worked
example. If you are adding a key that vim already has, read that first: the
key will not fire, and the reason is the lookup order above.

## Files

| file | holds |
| --- | --- |
| `keymap.lua` | the mode toggle |
| `registry.lua` | the seams everything else registers through |
| `api.lua` | the registry under its older names |
| `vimode/mode.lua` | which mode you are in |
| `vimode/keys.lua` | the key reader, and where the registry gets asked |
| `vimode/motions.lua` | the movement commands |
| `vimode/status.lua` | the status-bar pill |
| `ex/commandline.lua` | the `:` line itself |
| `ex/commands.lua` | vim's own ex commands |
| `ex/tokenize.lua` | splitting a command line into name, args, ranges |
| `ex/history.lua` | up and down through the history |
| `ex/suggest.lua` | path and command completion |
| `ex/fsops.lua` | the commands that touch the filesystem |
| `ex/help.lua` | `:help` |
| `shell/` | `:!cmd`, the scratch buffer, the terminal |
