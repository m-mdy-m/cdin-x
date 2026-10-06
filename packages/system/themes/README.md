# themes

The ten bundled themes and a switcher for them.

| theme | |
| --- | --- |
| `default` | what the editor falls back to; always present |
| `catppuccin-mocha`, `dracula`, `github-light`, `gruvbox-dark`, `monokai`, `nord`, `solarized-dark`, `solarized-light`, `tokyo-night` | the rest |

- **switcher** — <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> (`core:change-theme`)
  opens a searchable list of every theme the host knows about, not just the ten
  here. Writes `config.theme`, which is a host key: the editor applies it before
  plugins run and once more after, so a theme chosen in a previous session is
  already in place when the first frame is drawn.

## The layout is the host's, not ours

The host reads themes as `<root>/<name>/theme.lua` and that is fixed — it is in
cdin's extension contract, and the editor cannot be asked to look anywhere else.
So the ten keep exactly the shape they have always had, one directory each, and
this package's only job is to hand the host the directory they are in:

```text
themes/
├── default/theme.lua
├── nord/theme.lua
└── … nine more
```

Nothing is copied, generated or symlinked to make that work, and a theme package
from anywhere else is registered the same way. That is the answer to the open
question in the task: **theme packages keep the `<name>/theme.lua` shape inside a
parent directory**, rather than each becoming a `theme-*` package that would need
a generated root.

## What a `with` entry is

`with/themes.lua` persists the chosen theme into a session. It is declared in
`package.lua` and validated, but the kernel does not run `with` entries yet —
that arrives with the `vim` merge. Until then the theme is applied for the
session and not restored in the next one.