# workspace

Tabs, window splits, and what survives a restart. Three features of one package,
because they are three views of one thing: what the editor has open.

| feature | what it is |
| --- | --- |
| `tab` | tabs |
| `window` | splits, focus, layout |
| `session` | remember open files and restore them on the next start |

## tab

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>T</kbd> | new tab |
| <kbd>Ctrl</kbd>+<kbd>Tab</kbd> | next tab |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> | previous tab |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> | close tab |
| <kbd>Ctrl</kbd>+<kbd>1</kbd>–<kbd>9</kbd> | go to tab *n* |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>PageUp</kbd>/<kbd>PageDown</kbd> | first / last tab |

The tab bar lives on the status line, between the filename and the right-hand
group, and only appears once there is more than one tab. Pinning keeps a tab out
of the reorder; a closed tab can be reopened.

`tab:session-save` belongs to the `tab-session` feature and is described under
[session](#session) below, because it is about what survives a restart.

## window

| key | does |
| --- | --- |
| <kbd>Alt</kbd>+<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd>/<kbd>H</kbd> | split vertically / horizontally, or focus that direction |
| <kbd>Alt</kbd>+<kbd>↑</kbd>/<kbd>↓</kbd>/<kbd>←</kbd>/<kbd>→</kbd> | focus the view in that direction |
| <kbd>Alt</kbd>+<kbd>C</kbd> | close this view |
| <kbd>Alt</kbd>+<kbd>O</kbd> | close the others |
| <kbd>Alt</kbd>+<kbd>W</kbd> | equalise every pane |
| <kbd>Alt</kbd>+<kbd>=</kbd> | equalise |
| <kbd>Ctrl</kbd>+<kbd>\\</kbd> / <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>\\</kbd> | split / vertical split |

Layout sizing is <kbd>Alt</kbd> plus the arrows with a modifier, and the pane
tree is what the status line reads: one entry per view, so the tab counter and the
pane counter cannot disagree about how many things are open.

## session

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> | `session:save` — write the session now |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | `session:clear` — forget it |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd> | `session:show-info` — recent files, recent directories, where the state lives |

`session:save`, `session:open-recent` and `session:open-recent-dirs` are the same
thing asked three ways: the last two open the lists the first prints.

By default the session is also written when cdin exits, and read when it starts.

## Switching features off

Each of the three can be switched off on its own, and the point of keeping them in
one package rather than three is that you can:

```lua
return {
  features = {
    workspace = { session = false },
  },
}
```

With `session` off you keep tabs and splits and lose nothing but the restart
memory. With `tab` off you keep windows — which is how the editor works for someone
who splits but never opens a second file in the same window.

The panel shows them as `2/3 off` on the package's line, so you can see the state
without expanding it.

## The config keys are the host's

Six keys this package writes are read by **cdin**, not by this package:

```text
session_restore          session_restore_dir     session_restore_theme
session_max_recent       session_save_on_quit    tab_session_restore
```

They are at the top level of `config` and not namespaced under `workspace`,
because `config.workspace.session_restore` would be a key nothing reads — and the
feature would look configured and do nothing.

## tab-session, and why it is not a package

The open tabs can be part of the saved session. That is a fourth feature,
`tab-session`, and it used to be a package of its own called `tab-session`,
declared as an *integration* against `tab` and `session`.

It needs both, and neither should know about the other — which is a real
constraint and the reason the declaration existed. But as features of one package
the ordering is not a declaration any more, it is the order they are enabled in:
`session` before `tab-session`, because `tab-session` subscribes to
`session.on_quit()`. The harness asserts that order rather than trusting it.

A consequence worth knowing: with `tab-session` on and `session` off, there is no
quit hook to subscribe to, so nothing happens. That is the same thing the
dependency check used to guarantee.

## Commands

`tab:*`, `window:*` and `session:*` are spelled exactly as they always were —
about forty of them. Only the package name moved; a user's `init.lua` and a keymap
both name those commands, and renaming them would break working configuration.