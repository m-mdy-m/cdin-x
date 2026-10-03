# vim

Modal editing, and the `:` ex command line.

One of two plugins marked `essential = true` (the other is `manager`): a cdin build copies it in, because an
editor with no other modal editing isn't an editor. Which is also why it's
**self-contained** — it is bundled alone, so every `require "X.…"` inside it
resolves within its own subtree, and `make validate` checks that.

Vim mode knows nothing about tabs, trees, search or git. It offers seams
instead, and [`../../integration/vim/`](../../integration/vim) is where those get
filled.

[docs/extending-vim.md](../../../docs/extending-vim.md) — the seven seams and a
worked example.

**Full page:** [vim — what it does, what you press, and how it works](../../../docs/plugins/vim.md)

Inside `vimode/`, the editing grammar is four files that each do one job:
`text.lua` knows positions and ranges, `motions.lua` knows where a key sends the
caret, `textobjects.lua` knows what `i"` names, and `operators.lua` is the only
one that changes a buffer. `keys.lua` is the only one that knows a key exists.
That split is why `di"` is one rule rather than three key handlers that have to
agree.
