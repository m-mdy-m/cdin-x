# workspace

Tabs, windows and sessions: three views of one thing, which is what the editor
has open.

- **tab** — new, close, close-others, duplicate, pin, rename, reorder, and go to a
  tab by number. <kbd>Ctrl</kbd>+<kbd>T</kbd>, <kbd>Ctrl</kbd>+<kbd>Tab</kbd>,
  <kbd>Ctrl</kbd>+<kbd>1</kbd>–<kbd>9</kbd> and more; see `tab/keymap.lua`.
- **window** — split and close views, move focus, size a pane.
  <kbd>Alt</kbd>+<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd>/<kbd>H</kbd> and friends.
- **session** — remember open files, project and theme, and restore them on the
  next start. `Ctrl+Alt+S`, `Ctrl+Shift+D`, `Ctrl+Shift+R`.
- **tab-session** — include the open tabs in the saved session.
  No keys; `tab:session-save` is a command.

Each is a feature, so any of them can be switched off on its own — you can keep
your tabs and lose session restore, or close windows without touching either.

## Why one package

They used to be four packages, one of them (`tab-session`) an *integration*
declared against the other two. Inside one package that becomes a feature, and
the ordering the integration had to declare — `session` before `tab-session`,
because `tab-session` subscribes to `session.on_quit()` — is the order the kernel
enables features in. A user who has `tab-session` on and `session` off gets no
quit hook to subscribe to, which is the same thing the dependency check used to
guarantee.

## The config keys are the host's

`session` writes `session_restore`, `session_restore_dir`, `session_restore_theme`,
`session_max_recent` and `session_save_on_quit`; `tab-session` writes
`tab_session_restore`. None of them is namespaced, because the **host** reads them
— when it starts and when it quits. `config.workspace.session_restore` would be a
key nothing reads, and the feature would look configured and do nothing. The
values and their names are unchanged from before the merge.

## Commands and keys did not change

`tab:*`, `window:*`, `session:*` and `tab:session-save` are exactly as they were,
as are all thirty keystrokes. A user's `init.lua`, a keymap and cdin's own test
suite name them, so the *package* names are what moved and nothing else did.

## Internal layout

Each feature keeps its own directory and its own modules, required by name:

```text
tab/         impl.lua commands.lua keymap.lua manager.lua manager/
window/      commands.lua keymap.lua manager.lua manager/
session/     api.lua commands.lua keymap.lua manager/
tab-session/ session.lua
features/    tab.lua window.lua session.lua tab-session.lua
```

`tab/manager.lua` and `tab/manager/` both exist, and both spellings are used —
`workspace.tab.manager` is the file and `workspace.tab.manager.index` is the
directory's `init.lua`. That is how it worked before as `X.core.tab.manager` and
`X.core.tab.manager.index`, and the searcher resolves both in the same order.