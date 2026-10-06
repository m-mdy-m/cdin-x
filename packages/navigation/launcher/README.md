# launcher

Three ways into the editor. Each prompts and acts on the choice.

- **palette** — <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
  (`core:find-command`) lists every valid command and runs the one you pick.
- **finder** — <kbd>Ctrl</kbd>+<kbd>P</kbd> fuzzy-matches the project's files;
  <kbd>Ctrl</kbd>+<kbd>O</kbd> opens a file by path;
  <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> opens a folder.
- **modules** — no keys, on purpose. `core:reload-module` re-requires a loaded
  Lua module, `core:open-user-module` and `core:open-project-module` open the two
  config files that are run as code. They are deliberate, occasional actions, and
  binding a chord to each would be a key taken away for no gain.

Each is a feature, so any of them can be switched off on its own. The keystrokes
and the help entries go with the feature that owns them.

## `show_keybinds`

Whether the palette shows the keystroke beside each command. Declared as an
option in `package.lua`, so it is set in `packages.lua` rather than in
`config`:

```lua
return {
  packages = {
    { "launcher", opts = { show_keybinds = false } },
  },
}
```

It was `config.show_keybinds` before the merge. A user who set that in their own
`init.lua` has to move it: a config key the editor never reads, in a package that
owns it, is what declaring an option is for.

## Commands and keys did not change

`palette`, `finder` and `modules` are no longer package names. Every command name
(`core:find-command`, `core:find-file`, `core:open-file`, `core:open-folder`,
`core:reload-module`, `core:open-user-module`, `core:open-project-module`) and
every keystroke is exactly as it was, because a user's `init.lua`, a keymap and
cdin's own test suite all name them.