# launcher

Three entry points into the editor, and nothing else. Each prompts and acts on the
choice.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> | `core:find-command` — every command, by name |
| <kbd>Ctrl</kbd>+<kbd>P</kbd> | `core:find-file` — the project's files, fuzzy-matched |
| <kbd>Ctrl</kbd>+<kbd>O</kbd> | `core:open-file` — a path |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> | `core:open-folder` — a directory |

`core:reload-module`, `core:open-user-module` and `core:open-project-module` are in
the palette and have no keys, deliberately: a global binding for "reload a Lua
module" would fire while you were typing.

## Three features, not three packages

`palette`, `finder` and `modules` were packages once. They are now three features
of `launcher`, and the reason is the strokes: those four keys are the most
contested in the editor, and three packages claiming them separately is three
registration cycles and three chances to collide. As one package they are three
features you can switch off individually.

| feature | what you lose by turning it off |
| --- | --- |
| `palette` | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> does nothing |
| `finder` | <kbd>Ctrl</kbd>+<kbd>P</kbd>, <kbd>Ctrl</kbd>+<kbd>O</kbd> and <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> do nothing |
| `modules` | three commands disappear from the palette |

Nothing is *lost* by turning a feature off — every command it would have bound is
still registered and still in the palette. You just have to know its name.

Switch them from the extension panel (<kbd>F</kbd> under `launcher`), or in your
`packages.lua`:

```lua
return {
  features = {
    launcher = { finder = false },
  },
}
```

## The option

| option | default | does |
| --- | --- | --- |
| `show_keybinds` | `true` | show the keystroke beside each command in the palette |

This one was `config.show_keybinds`, and it moved. A user who set it in
`~/.config/cdin/user/init.lua` has to change it, because the package now owns it:

```lua
return { features = { launcher = { show_keybinds = false } } }
```

## How the matching works

**The palette is fuzzy, and so is the finder.** A non-contiguous subsequence
match, so `fnf` finds *core: find file*. That is `common.fuzzy_match`, and it is a
stronger match than [menu](menu.md)'s, which is a plain substring — the menu has
letter shortcuts and a small list, so exactness costs nothing there.

The two differ in what they read. The palette matches against
`command.get_all_valid()`, which is commands whose *predicate* currently holds, so
a command you cannot run right now is not offered. The finder matches against the
project's file list, and distinguishes files from directories by their trailing
separator rather than by `entry.type` — which on the array the finder is handed is
always nil, so asking would classify everything as one thing.

## Why the palette can be missing

The mechanism is not optional, only the thing built on it. `core.command_view` —
the prompt, its suggestion list, the selection — is a runtime service, always
present. What you do with it is a choice: the palette, the finder, the menu, the
git commit message, the project-folder prompt are all the same prompt with
different text in it.