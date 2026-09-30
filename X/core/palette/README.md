# palette

The command palette: every command the editor has right now, fuzzy-matched by
name.

<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>, or `core:find-command`.

It is a plugin rather than part of the editor because the *mechanism* is always
available — `core.command_view` is a runtime service — and a palette is a
choice about what to do with it. The palette, the file finder and the project
folder prompt all use the same prompt and are all optional.

The command list is read when the palette opens, not when the plugin loads, so
a command registered or unloaded in between shows up.

**Full page:** [palette — what it does, what you press, and how it works](../../../docs/plugins/palette.md)
