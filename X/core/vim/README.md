# vim

Modal editing, and the `:` ex command line.

The one plugin marked `essential = true`: a cdin build copies it in, because an
editor with no other modal editing isn't an editor. Which is also why it's
**self-contained** — it is bundled alone, so every `require "X.…"` inside it
resolves within its own subtree, and `make validate` checks that.

Vim mode knows nothing about tabs, trees, search or git. It offers seams
instead, and [`../../integration/vim/`](../../integration/vim) is where those get
filled.

[docs/extending-vim.md](../../../docs/extending-vim.md) — the seven seams and a
worked example.

**Full page:** [vim — what it does, what you press, and how it works](../../../docs/plugins/vim.md)
