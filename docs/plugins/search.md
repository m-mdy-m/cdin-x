# search

Find and replace inside the document, and search across the project.

## In the document

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>F</kbd> | `find-replace:find` |
| <kbd>F4</kbd> | `find-replace:repeat-find` — the same search again |
| <kbd>R</kbd> | `find-replace:previous-find` — the same search, backwards |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>H</kbd> | `find-replace:clear-highlight` |
| <kbd>Ctrl</kbd>+<kbd>D</kbd> | select the next match — or select the word, when there is no match |
| <kbd>Esc</kbd> | close the prompt |

Matches highlight as you type. <kbd>Enter</kbd> jumps to the next one and keeps
the prompt out of the way; <kbd>R</kbd> then walks backwards through what you
have already seen.

The search is a **plain substring, case-insensitive, and it wraps** — reaching
the end continues at the top. Two things follow from that, and both are worth
knowing before you go looking for the option:

- There is no case-sensitive mode. `no_case = true` is set on both search
  commands and nothing reads it back, so a search for `error` will also find
  `Error`. Matching a case exactly is not something this plugin offers.
- There is no prefix syntax either — no `/` for literal, no `c/` for
  case-sensitive, no `r/` for regex. What you type is what is searched, and if
  you want a Lua pattern instead of a substring you ask for it with a
  different command.

| command | searches for |
| --- | --- |
| `find-replace:find` | the text, literally |
| `find-replace:find-pattern` | the text as a **Lua pattern** |

`find-pattern` is the same prompt with `pattern = true`, and it is what
`vim-search`'s <kbd>*</kbd> is not — that one takes the word under the cursor
and searches for it literally, which is the safe reading.

## Replacing

The prompt switches to replace once you have a search. In the palette the
commands are:

| command | does |
| --- | --- |
| `find-replace:find-pattern` | search for what is under the cursor |
| `find-replace:replace` | replace the current match |
| `find-replace:replace-pattern` | replace using the last pattern |
| `find-replace:replace-symbol` | replace every match in the document |
| `find-replace:select-next` | next match, without opening the prompt |
| `find-replace:repeat-find` / `previous-find` | walk the matches |

## Across the project

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | `project-search:find` |
| <kbd>F5</kbd> | `project-search:refresh` — re-run the last search |
| <kbd>↑</kbd> / <kbd>↓</kbd> | move through the results |
| <kbd>Enter</kbd> | open the selected result |

| command | does |
| --- | --- |
| `project-search:find-pattern` | search for what is under the cursor |
| `project-search:fuzzy-find` | fuzzy rather than substring |
| `project-search:open-selected` | open the highlighted file, at the line |

The results view is a list of `file:line` with the matching text, and opening
one puts the cursor on the match rather than at the top of the file — which is
the only thing that makes a project-wide search worth having.

## In vim mode

If `vim-search` is installed, <kbd>/</kbd> opens the same prompt, <kbd>n</kbd>
repeats it, <kbd>N</kbd> repeats it backwards, and <kbd>*</kbd> searches for the
word under the cursor. <kbd>*</kbd> with no word under the cursor deliberately
does nothing rather than opening an empty search.

## How it works

Four files that do not know about each other, on purpose.

```text
search/manager/    shared state, document helpers, highlight state
search/buffer.lua  search, find, replace within a document
search/project.lua the project-wide results view
search/commands.lua, keymap.lua   registration only
```

**`buffer.lua` and `project.lua` register nothing.** Commands and bindings live
in their own files, so an integration can use the search API without also
inheriting search's keys. `vim-search` is exactly that case: it reaches the
commands by name and claims no bindings of its own beyond the four vim keys.

**`manager/` holds the state**, because both halves need to agree on what the
current pattern is, which matches are highlighted, and where the cursor is.
Two copies of that would be two answers to one question.

**Highlights are managed, not scattered.** The manager owns which ranges are
marked, so a document search and a project search that overlap do not fight
over the same range — the second one replaces the first rather than painting
over it.

**The two keymaps that overlap are lists, not overrides.** <kbd>Ctrl</kbd>+<kbd>D</kbd>
is bound to `{ "find-replace:select-next", "doc:select-word" }`: the first
command whose predicate holds runs, and a predicate is what "there is a
selected match" means. So the key belongs to search while searching and to the
document otherwise, and neither plugin knows the other exists.

**`doc:select-word` losing is not a bug.** `keymap.add(MAP, true)` replaces
whatever the stroke had. That is the right call for a plugin that owns a key,
and the wrong call for one that is adding to it — which is why the second
argument is written down at every call site rather than defaulted.

## Files

| file | holds |
| --- | --- |
| `buffer.lua` | document search, find, replace |
| `project.lua` | project-wide search and the results view |
| `commands.lua` | the `find-replace:*` and `project-search:*` names |
| `keymap.lua` | the keys above |
| `manager/init.lua` | the state both halves share |
