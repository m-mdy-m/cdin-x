# finder

Opening things by name.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>P</kbd> | `core:find-file` — fuzzy-match the project's files |
| <kbd>Ctrl</kbd>+<kbd>O</kbd> | `core:open-file` — type or complete a path |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> | `core:open-folder` — type or complete a directory, and switch the project to it |

All three are the same shape: a prompt, a list that narrows as you type, and an
action on what you accept. <kbd>Enter</kbd> takes it, <kbd>Esc</kbd> backs out,
and the arrows move.

## The three are different

**`find-file` searches the project.** Not your disk — the file list the project
scanner built, which is why it is fast on a large tree and why it only knows
about what is in the project. Typing matches a subsequence, so `fuim` finds
`finder/init.lua`.

**`open-file` takes a path.** Relative to the working directory, with
completion from the filesystem. It will open something outside the project,
which is the point of having both.

**`open-folder` switches the project.** It does that and nothing else.

## Switching projects

`core:open-folder` opens a directory and then tells the runtime to make it the
project. It does not also `cd` — the runtime owns that, because the working
directory *is* the project as far as the editor is concerned, and three things
have to agree about it: `core.project_dir`, the file list, and the revision
counter the views read. A plugin that moved the directory on its own would
leave the revision stale, and the tree would show the old project until
something else forced a rescan — which is a bug you would see as "the tree is
wrong" and would spend a long time looking in the tree.

## How it works

**One plugin, not three.** Three commands of the same shape as three plugins
would be three copies of the path-resolution code and three places for the
error messages to drift. One plugin has one `clean()`, one error vocabulary, and
one directory suggester.

**`core:open-folder` suggests directories through `core.fs.list`, not
`system.list_dir`.** They look interchangeable and are not: `list_dir` returns
an array of *names*, so `entry.type` on one of its values is nil and every
directory is filtered out — the prompt opens and offers nothing, with no error
anywhere to say why. `fs.list` stats each entry and returns
`{ name, type, size }`, which is what tells a directory from a file. The other
two commands go through `common.path_suggest`, which reaches the same answer
with its own stat per name.

That is the kind of bug that costs an afternoon, and the reason it is written
down at the call site as well as here.

**The file list is read at open time, not at load.** The project scanner
rebuilds it in place, so caching it would mean searching a stale list.

**The runtime keeps `core.project_files` and `core.set_project_dir`; the
prompts that drive them are a choice.** That split is the split between the
project scanner — which the editor needs — and the finder — which it does not.
Uninstall this and the editor still knows what your project is; it just does not
offer you a way to change it from the keyboard.

## Files

Single file, `init.lua`. It is small enough that splitting it would be three
files each holding one function.
