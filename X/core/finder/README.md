# finder

Finding and opening things by name or path.

| keystroke | command | does |
| --- | --- | --- |
| <kbd>Ctrl</kbd>+<kbd>P</kbd> | `core:find-file` | fuzzy-match the project's files |
| <kbd>Ctrl</kbd>+<kbd>O</kbd> | `core:open-file` | type or complete a path, and open it |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> | `core:open-folder` | type or complete a directory, and switch the project to it |

Three commands of the same shape — prompt through `core.command_view`, act on
what was accepted — so they are one plugin rather than three. One `clean()`,
one error vocabulary, one directory suggester.

`core:open-folder` goes through the runtime's `core.set_project_dir` and does
nothing else, because the runtime owns that transition.

Details: [docs/installing-plugins.md](../../../docs/installing-plugins.md).

**Full page:** [finder — what it does, what you press, and how it works](../../../docs/plugins/finder.md)
