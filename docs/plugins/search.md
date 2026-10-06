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

- There is no case-sensitive mode. `no_case = true` is passed to the host's
  `core.doc.search` on both commands, and nothing in this plugin reads it back;
  matching a case exactly is not something the plugin itself offers.
- There is no prefix syntax either — no `/` for literal, no `c/` for
  case-sensitive, no `r/` for regex. What you type is what is searched, and if
  you want a Lua pattern instead of a substring you ask for it with a
  different command.

| command | searches for |
| --- | --- |
| `find-replace:find` | the text, literally |
| `find-replace:find-pattern` | the text as a **Lua pattern** |

`find-pattern` is the same prompt with `pattern = true`, and it is what
the vim `with` entry's <kbd>*</kbd> is not — that one takes the word under the cursor
and searches for it literally, which is the safe reading.

## Replacing

None of the replace commands has a key, and none of them continues a search you
already have. Each opens its own two prompts — what to find, then what to put
there — and then rewrites the **whole document**, not the match you were
looking at. There is no "replace this one" and no "replace all, asking".

| command | does |
| --- | --- |
| `find-replace:replace` | every literal instance of the text, in the document |
| `find-replace:replace-pattern` | every instance of a **Lua pattern** you type |
| `find-replace:replace-symbol` | every symbol matching `config.symbol_pattern` whose text equals what you typed |
| `find-replace:select-next` | next match, without opening the prompt |
| `find-replace:repeat-find` / `previous-find` | walk the matches |

The old text is escaped before `gsub` in `replace`, so a `%` or a `-` in what
you search for is literal. `replace-pattern` does not escape, because the whole
point is that it is a pattern. `replace-symbol` matches on
`config.symbol_pattern` — the host's own identifier pattern, the same one the
treeview and autocomplete use — and replaces only the captures that equal your
input, so renaming one function does not rename the one that shares its prefix.

## Across the project

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | `project-search:find` |
| <kbd>F5</kbd> | `project-search:refresh` — re-run the last search |
| <kbd>↑</kbd> / <kbd>↓</kbd> | move through the results |
| <kbd>Enter</kbd> | open the selected result |

| command | does |
| --- | --- |
| `project-search:find-pattern` | search the project for a **Lua pattern** |
| `project-search:fuzzy-find` | fuzzy rather than substring |
| `project-search:open-selected` | open the highlighted file, at the line |

The results view is a list of `file:line:col` with the matching text and 40
characters of context, and opening one puts the cursor on the match rather than
at the top of the file — which is the only thing that makes a project-wide
search worth having.

It searches exactly what the host's project scanner produced
(`core.project_files`), so a file the scanner has not reached, or one hidden by
[`treeview`](treeview.md)'s `ignore_files`, is not searched. The results pane is
attached to whatever pane is focused when the search finishes.

## In vim mode

With `vim` installed, <kbd>/</kbd> opens the same prompt, <kbd>n</kbd>
repeats it, <kbd>N</kbd> repeats it backwards, and <kbd>*</kbd> searches for the
word under the cursor. <kbd>*</kbd> with no word under the cursor deliberately
does nothing rather than opening an empty search.

It also adds a **Search** section to [the menu](menu.md), with its own
single-letter keys.

## How it works

Four files that do not know about each other, on purpose.

```text
search/manager/    shared state, document helpers, highlight state
search/buffer.lua  search, find, replace within a document
search/project.lua the project-wide results view
search/commands.lua, keymap.lua   registration only
```

**`buffer.lua` and `project.lua` register nothing.** Commands and bindings live
in their own files, so another package can use the search API without also
inheriting search's keys. The vim `with` entry on `search` is exactly that case: it reaches the
commands by name and claims no bindings of its own beyond the four vim keys.

**`manager/` holds the state**, because both halves need to agree on what the
current pattern is, which matches are highlighted, and where the cursor is.
Two copies of that would be two answers to one question.

**Highlights are managed, not scattered.** The manager owns which ranges are
marked, so a document search and a project search that overlap do not fight
over the same range — the second one replaces the first rather than painting
over it.

**The two keymaps that overlap are joined by prepending, not by lists.**
<kbd>Ctrl</kbd>+<kbd>D</kbd> is bound by this plugin to the plain string
`find-replace:select-next`. `keymap.add()` *prepends*, so the stroke now has two
commands on it: search's first, and the core's `doc:select-word` still behind it.
The first whose predicate holds runs — search's predicate is "this document has
a selection" — so the key belongs to search while a match is selected and to the
document otherwise, and neither plugin knows the other exists.

There is not a single list-valued binding in this plugin.

**`keymap.add(MAP, true)` would break all of it.** The second argument
replaces the *whole* chain for a stroke rather than joining it, and this plugin
also binds <kbd>↑</kbd>, <kbd>↓</kbd> and <kbd>Enter</kbd> for the results view.
Those are the document's cursor, the `:` prompt's submit, and the autocomplete
popup's selection; overwriting them leaves a document with dead arrows and a
command line with a dead <kbd>Enter</kbd>. The reason is written into the file
next to the binding, because it is the kind of thing that gets "tidied up" once.

## What clears what

`find-replace:clear-highlight` calls `clear_doc_search`, which drops the
highlights **and** the stored `last_fn`. `repeat-find` and `previous-find` are
gated on that function existing, so <kbd>F4</kbd> and <kbd>R</kbd> go dead — and
disappear from the palette — the moment you clear the highlight. That is one
call, and it is not obvious from its name.

The previous-find history is per-document and capped at 50 entries: switching
documents discards it, and `find-replace:previous-find` then reports
`No previous finds`.

## Files

| file | holds |
| --- | --- |
| `buffer.lua` | document search, find, replace |
| `project.lua` | project-wide search and the results view |
| `commands.lua` | the `find-replace:*` and `project-search:*` names |
| `keymap.lua` | the keys above |
| `manager/init.lua` | the state both halves share |
