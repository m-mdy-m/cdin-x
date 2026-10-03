# vim

Modal editing, and the `:` command line.

One of two plugins marked `essential` — the other is `manager`. A cdin build copies it in, because
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

Four, plus the `:` line. The mode is shown as a coloured pill at the left of the
status bar, and it is **per view** — two documents side by side can be in
different modes at once, and switching between them changes neither.

| mode | how you get into it | how you leave it |
| --- | --- | --- |
| **normal** | the default when you open a document, and <kbd>Esc</kbd> from any other mode | — |
| **insert** | <kbd>i</kbd> <kbd>a</kbd> <kbd>I</kbd> <kbd>A</kbd> <kbd>o</kbd> <kbd>O</kbd> <kbd>s</kbd> <kbd>S</kbd> <kbd>C</kbd>, and <kbd>c</kbd> followed by a motion or a text object | <kbd>Esc</kbd> |
| **visual** | <kbd>v</kbd> | <kbd>Esc</kbd>, or <kbd>v</kbd> again |
| **visual line** | <kbd>V</kbd> | <kbd>Esc</kbd>, or <kbd>V</kbd> again |
| **command** | <kbd>:</kbd> | <kbd>Esc</kbd>, or running what you typed |

The ones that take typing, spelled out:

- <kbd>i</kbd> — insert **at** the caret. <kbd>a</kbd> — insert **after** it.
  <kbd>I</kbd> and <kbd>A</kbd> are those same two ideas at the first non-blank
  and the end of the line. <kbd>o</kbd> and <kbd>O</kbd> open a line below or
  above and insert into it.
- <kbd>s</kbd> — change the character under the caret and type over it.
  <kbd>S</kbd> is the whole line, <kbd>C</kbd> is to the end of the line, and
  <kbd>c</kbd> followed by a motion or a text object is the general form:
  <kbd>ci"</kbd> changes inside the quotes, <kbd>cw</kbd> changes a word.

**<kbd>Esc</kbd> is the key that matters.** It is the way out of insert mode, out
of a selection, and out of the `:` line — and nothing you can press by accident
leaves you somewhere you cannot get back from.

### Selecting: <kbd>v</kbd> and <kbd>V</kbd>

<kbd>v</kbd> starts a character-wise selection at the caret. Move with any motion
— <kbd>w</kbd>, <kbd>b</kbd>, <kbd>e</kbd>, <kbd>j</kbd>, the arrows — and the
selection grows with you. Press <kbd>v</kbd> again to drop it, or <kbd>Esc</kbd>.

<kbd>V</kbd> is the same for whole lines: it takes the line the caret is on, and
<kbd>j</kbd> / <kbd>k</kbd> add the lines below and above. In either mode you can
then press <kbd>d</kbd> to delete, <kbd>y</kbd> to copy, <kbd>c</kbd> to change,
<kbd>u</kbd> / <kbd>U</kbd> to change case, and <kbd>o</kbd> to swap which end
the caret is on. <kbd>i</kbd>… or <kbd>a</kbd>… re-aims the selection at a text
object instead.

The two modes use the **same colour** in the status pill on purpose: they differ
in what they select, not in what they are. The label is what tells them apart —
`[VISUAL]` against `[VISUAL LINE]`.

**There is no replace mode.** <kbd>r</kbd> takes the characters you give it,
replaces that many, and puts you straight back in normal mode, which is what
vim's <kbd>r</kbd> does.

## Moving

Normal mode. Each of these is a *rule* rather than a command name, which is what
lets an operator use it: <kbd>dw</kbd> is not <kbd>d</kbd> then <kbd>w</kbd>, it
is one range from the caret to wherever <kbd>w</kbd> would have gone. They are
declared as data in `vimode/motions.lua`.

| key | goes to |
| --- | --- |
| <kbd>h</kbd> <kbd>l</kbd> | one character left / right, never across a line |
| <kbd>j</kbd> <kbd>k</kbd> | one line down / up, keeping the column |
| <kbd>←</kbd> <kbd>→</kbd> <kbd>↑</kbd> <kbd>↓</kbd> | the same four, under the name the host reports them — see below |
| <kbd>w</kbd> <kbd>W</kbd> | next word start / next WORD start |
| <kbd>b</kbd> <kbd>B</kbd> | previous word start / previous WORD start |
| <kbd>e</kbd> <kbd>E</kbd> | end of this word, or of the next one |
| <kbd>0</kbd> | start of line |
| <kbd>^</kbd> | first non-blank of the line |
| <kbd>$</kbd> | end of line; with a count, the end of the line below |
| <kbd>gg</kbd> / <kbd>G</kbd> | first / last line, or line *n* with a count |
| <kbd>g</kbd><kbd>_</kbd> | last non-blank of the line |
| <kbd>f</kbd> <kbd>F</kbd> <kbd>t</kbd> <kbd>T</kbd> + a character | to or from that character on this line, stopping one short for <kbd>t</kbd> and <kbd>T</kbd> |
| <kbd>;</kbd> <kbd>,</kbd> | repeat that find, forwards or backwards |
| <kbd>%</kbd> | the bracket that matches this one |
| <kbd>{</kbd> <kbd>}</kbd> | previous / next paragraph |
| <kbd>(</kbd> <kbd>)</kbd> | previous / next sentence |
| <kbd>+</kbd> <kbd>-</kbd> | first non-blank of the line below / above |
| <kbd>\|</kbd> | column *n* |
| <kbd>H</kbd> <kbd>M</kbd> <kbd>L</kbd> | top / middle / bottom of the window |

A count goes in front of any of them, so <kbd>3</kbd><kbd>w</kbd> moves three
words. Paging is <kbd>Ctrl</kbd>+<kbd>F</kbd> and <kbd>Ctrl</kbd>+<kbd>B</kbd> for
a screen, <kbd>Ctrl</kbd>+<kbd>U</kbd> and <kbd>Ctrl</kbd>+<kbd>D</kbd> for half
of one. In vim mode <kbd>Ctrl</kbd>+<kbd>D</kbd> is half a screen rather than the
editor's select-word, which <kbd>iw</kbd> already does.

### The arrow keys

The four arrows are the four `hjkl` motions under another name, and they are
mapped as exactly that — one character, not one word. So <kbd>3</kbd> then
<kbd>→</kbd> moves three characters, <kbd>d</kbd> then <kbd>→</kbd> deletes to
the end of the line, and in visual mode an arrow grows the selection the way
<kbd>l</kbd> does.

They work in **normal and visual mode, and only while the document is the
focused view**. That gate is deliberate: [`treeview`](treeview.md),
[`search`](search.md) and the autocomplete popup all bind these same four keys
for their own lists, and each wants them while *it* has focus. So arrows move
the caret in a document, the tree selection in the tree, and the results list in
project search — with no configuration and no plugin able to take them away from
the others.

## Text objects

Two keys that name a *region* instead of a place. The first is <kbd>i</kbd> for
the inside, or <kbd>a</kbd> for the whole thing including the delimiters. They
work after an operator (<kbd>di"</kbd>), after a motion, or on their own in
visual mode to re-aim a selection (<kbd>vi"</kbd>).

| key | names |
| --- | --- |
| <kbd>iw</kbd> <kbd>aw</kbd> | a word / a word and the whitespace around it |
| <kbd>iW</kbd> <kbd>aW</kbd> | the same, with punctuation not counted separately |
| <kbd>i"</kbd> <kbd>a"</kbd> | the text inside the nearest pair of double quotes |
| <kbd>i'</kbd> <kbd>a'</kbd> | …single quotes |
| <kbd>i(</kbd> <kbd>a(</kbd>, or <kbd>ib</kbd> <kbd>ab</kbd> | inside the innermost <kbd>()</kbd> pair |
| <kbd>i[</kbd> <kbd>a[</kbd> | inside <kbd>[]</kbd> |
| <kbd>i{</kbd> <kbd>a{</kbd> | inside <kbd>{}</kbd> |
| <kbd>i&lt;</kbd> <kbd>a&lt;</kbd> | inside <kbd>&lt;&gt;</kbd> |
| <kbd>it</kbd> <kbd>at</kbd> | inside an HTML or XML tag, across lines |
| <kbd>ip</kbd> <kbd>ap</kbd> | a paragraph, without / with the blank line after it |
| <kbd>is</kbd> <kbd>as</kbd> | a sentence |

So <kbd>ci"</kbd> changes what is inside the quotes, <kbd>di(</kbd> deletes a
call's arguments, <kbd>dat</kbd> removes a whole element. If the name covers
nothing here — <kbd>di(</kbd> outside a bracket, <kbd>di"</kbd> on a line with one
quote in it — nothing happens, which is what vim does.

**There is no <kbd>in</kbd> / <kbd>an</kbd>.** They need a document-wide search
and a decision about which of several matches to take, and search is a plugin
that vim core may not reach for. What they would do is <kbd>*</kbd> and then
<kbd>c</kbd><kbd>w</kbd>.

## Editing

An *operator* applies to a range: a motion (<kbd>dw</kbd>), a text object
(<kbd>di"</kbd>), the line (<kbd>dd</kbd>), or lines and a count
(<kbd>3</kbd><kbd>dd</kbd>). Counts go on either side of an operator and
multiply, so <kbd>2</kbd><kbd>d</kbd><kbd>3</kbd><kbd>w</kbd> deletes six words.

| key | does |
| --- | --- |
| <kbd>d</kbd> | delete a motion, an object, or the line |
| <kbd>y</kbd> | yank one |
| <kbd>c</kbd> | change one, and insert |
| <kbd>=</kbd> | indent a motion or an object |
| <kbd>&gt;</kbd> <kbd>&lt;</kbd> | shift right / left |
| <kbd>gu</kbd> <kbd>gU</kbd> <kbd>g~</kbd> | lower-case / upper-case / toggle, over the same three things |
| <kbd>x</kbd> | cut the character under the caret, onto the clipboard |
| <kbd>X</kbd> | cut the one before it |
| <kbd>s</kbd> / <kbd>S</kbd> | change one character / the whole line |
| <kbd>D</kbd> / <kbd>C</kbd> | to the end of the line |
| <kbd>J</kbd> | join with the line below |
| <kbd>i</kbd> <kbd>I</kbd> | insert at the caret / at the first non-blank |
| <kbd>a</kbd> <kbd>A</kbd> | insert after the caret / at the end of the line |
| <kbd>o</kbd> <kbd>O</kbd> | open a line below / above, and insert |
| <kbd>p</kbd> <kbd>P</kbd> | paste after / before |
| <kbd>u</kbd> | undo |
| <kbd>Ctrl</kbd>+<kbd>Y</kbd> | redo |
| <kbd>r</kbd> then a character | replace the characters under the caret |
| <kbd>~</kbd> | toggle the case of one character |
| <kbd>.</kbd> | repeat the last change, at the new caret position |
| <kbd>v</kbd> / <kbd>V</kbd> | visual / visual line |
| <kbd>o</kbd> in visual | swap which end the caret is on |
| <kbd>d</kbd> <kbd>x</kbd> <kbd>c</kbd> <kbd>y</kbd> in visual | act on the selection |
| <kbd>u</kbd> / <kbd>U</kbd> in visual | lower-case / upper-case it |
| <kbd>&gt;</kbd> <kbd>&lt;</kbd> <kbd>=</kbd> in visual | shift / indent it |
| <kbd>i</kbd>… or <kbd>a</kbd>… in visual | re-aim the selection at a text object |

**`r` is vim's replace, and redo moved to <kbd>Ctrl</kbd>+<kbd>Y</kbd>.** That is
the one key whose meaning changed. <kbd>Ctrl</kbd>+<kbd>Y</kbd> is already the
editor's redo stroke, so nothing was taken away from it — but if you have been
pressing <kbd>r</kbd> to redo, use <kbd>Ctrl</kbd>+<kbd>Y</kbd> now.

**`cw` behaves like `ce` on a word.** The one place where <kbd>c</kbd> is not
<kbd>d</kbd>: changing a word does not also eat the space after it. On
whitespace it really is <kbd>dw</kbd>.


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
| `:ls` | list a directory's contents in a scratch buffer |
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
vim/vimode/           the key reader, positions, motions, text objects,
                      the operators, the modes and the status pill
vim/ex/               the : line — tokenizer, history, completion, the command set
vim/shell/            :!cmd, the scratch buffer, the terminal window
vim/registry.lua      the seven seams
vim/api.lua           an older spelling of the registry, kept working
```

**A key is looked up in this order.** Vim's own keys first, and only if they
decline does the registry get asked. That ordering is what makes it safe for
an integration to claim <kbd>m</kbd>: it can add a key, but it cannot shadow one
vim already handles.

The one exception is a **capital letter**, which is the single spelling both
vocabularies can claim: <kbd>N</kbd> is vim's "search backwards" and
vim-search's "previous find", and <kbd>M</kbd> is vim's "middle of the window"
and a menu. Shift and <kbd>d</kbd> arrives as the character `d`, so without the
exception <kbd>D</kbd> would reach the operator table as a plain <kbd>d</kbd> and
become a pending delete instead of deleting to the end of the line — and
<kbd>J</kbd> would be answered by the motion table as <kbd>6j</kbd>. So a
shifted letter skips vim's own tables and asks the registry first.

**An operator needs a range, and a motion is not a range.** That is the whole
reason `vimode/motions.lua` holds rules rather than command names. Given a key,
the old table could say which cdin command to run; it could not say where the
motion *ended*, which is the only thing <kbd>dw</kbd> needs in order to be one
range from the caret to the start of the next word. So a motion answers an
endpoint plus two facts about it — whether the character it lands on belongs to
the range (<kbd>$</kbd> and <kbd>e</kbd> do, <kbd>w</kbd> and <kbd>h</kbd> do
not), and whether the range is whole lines (<kbd>j</kbd> and <kbd>G</kbd> are).
One rule, read by normal mode, by a pending operator and by <kbd>.</kbd>
alike, so all three agree about where <kbd>w</kbd> goes.

**Shifted punctuation arrives as its base key.** The host reports the
*unshifted* key and a separate shift flag, so <kbd>"</kbd> arrives as
<kbd>'</kbd> with shift held and <kbd>$</kbd> as <kbd>4</kbd> with shift held.
`vimode/keys.lua` maps those to the characters they produce. Without that,
<kbd>"</kbd> matches nothing, the capitals table has no branch for it, the key
is swallowed — and <kbd>yi"</kbd>, <kbd>di"</kbd> and <kbd>ci"</kbd> do nothing
at all with nothing on screen to say why.

**Modes are the state, not the views.** `vimode/mode.lua` holds normal /
insert / visual and nothing about layout. The status pill reads it. That is why
the pill is registered through `core.register_status_pill` rather than drawn by
vim mode itself — the status bar owns its own drawing and offers a seam.

**The ex command set is a registry, not a table.** `ex/commands.lua`
registers its commands through the same `registry.register_command` that
integrations use, which is why `:tabnew` appears in `:help` and in completion
only when the tab plugin is actually installed. The registry collects every
distinct `help` string and prints them in registration order.

**Essential means self-contained** — for *this* plugin. The bundler copies it *alone* into
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
| `vimode/keys.lua` | the key reader, the half-typed states, and where the registry gets asked |
| `vimode/text.lua` | position and range arithmetic over a document |
| `vimode/motions.lua` | where each motion goes, and what it means to an operator |
| `vimode/textobjects.lua` | the `i`/`a` objects |
| `vimode/operators.lua` | applying an operator to a span, and the clipboard |
| `vimode/mode.lua` | which mode you are in |
| `vimode/status.lua` | the status-bar pill |
| `ex/commandline.lua` | the `:` line itself |
| `ex/commands.lua` | vim's own ex commands |
| `ex/tokenize.lua` | splitting a command line into a name and args. **No ranges** — `:5`, `:%d`, `:'a,'b` are not parsed |
| `ex/history.lua` | up and down through the history |
| `ex/suggest.lua` | path and command completion |
| `ex/fsops.lua` | the commands that touch the filesystem |
| `ex/help.lua` | `:help` |
| `shell/` | `:!cmd`, the scratch buffer, the terminal |
