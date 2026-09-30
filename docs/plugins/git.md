# git

Running git, and knowing what state the repository is in.

Install it and the status bar grows a branch. That is most of what this plugin
does on its own — **it registers no commands and binds no keys**, on purpose.
Anything you would want to *do* with git belongs in an integration, and
[`vim-git`](../../X/integration/vim/vim-git) is the one that ships.

## What you get on its own

The status bar, at the left of the document view:

```text
main  ↑2 ~3        branch, commits ahead, files changed
main  -            branch, no upstream
(main 1a2b3c)      detached HEAD
```

and nothing at all when you are not in a repository, or when the plugin is not
installed. There is no "git is missing" state, because there is no code path
that can fail — the status bar asks a hook, and with no hook it draws nothing.

| reading | means |
| --- | --- |
| `↑2` | two commits ahead of the upstream |
| `↓3` | three behind |
| `-` | no upstream tracking branch |
| `+1` | one file staged |
| `~4` | four files changed or untracked |
| `!2` | two files in conflict |

The counts come from `git status --porcelain`, not from parsing human output,
which is why an unusual filename or a path with a newline does not confuse it.

## Using it from a menu

With `vim-git` installed, <kbd>m</kbd> → Git, or the commands:

| command | runs |
| --- | --- |
| `vim-git:status` | `git status` |
| `vim-git:log` | `git log --oneline -20` |
| `vim-git:diff` | `git diff` |
| `vim-git:add-all` | `git add .` |
| `vim-shell:git-status` / `git-log` / `git-diff` | the same three, under the shell's names |

All of them open the output in a scratch buffer, the same one `:!make` writes
to. Nothing is piped through a pager, and nothing is interactive — `git commit`
without `-m` would sit there waiting, which is why the menu's Commit entry asks
for the message first instead of running the bare command.

The menu also has Commit, Push, Pull and Branches, which are menu entries rather
than commands.

## Using it from your own plugin

```lua
local git = require "X.core.git.api"
```

| what | what it is |
| --- | --- |
| `git.exe(cmd)` | run a command, return output and success |
| `git.exe_cwd(cmd, dir)` | the same, in a directory |
| `git.popen(cmd)` | a streaming handle, for something long |
| `git.normalize_path(p)` | a path the way git writes it |
| `git.IS_WIN` | the platform, so you don't have to ask `core` |
| `git.status` | the live status table (below) |
| `git.status.is_ignored(path)` | is this path in `.gitignore` |
| `git.status.refresh_ignored_now()` | re-read `.gitignore` |
| `git.recipes` | the shared shell command strings |
| `git.sync_registry` | clone or pull the extension catalog |

`git.status` is a live table, not a function — it is polled on a coroutine
every `config.git_update_rate` seconds (2 by default) and the status bar reads
whatever is in it:

```lua
git.status.branch       -- "main", or "(detached)" with a hash, or nil
git.status.has_remote   -- an upstream tracking branch exists
git.status.ahead        -- commits ahead
git.status.behind       -- commits behind
git.status.staged       -- files staged
git.status.unstaged     -- files changed or untracked
git.status.conflicts    -- files in conflict
git.status.repo_dirty   -- anything at all
```

## The recipes

`git.recipes` is a table of shell command strings, and it exists so the whole
repository spells each git invocation the same way:

```lua
status = "git status"
log    = "git log --oneline -20"
diff   = "git diff"
add_all= "git add ."
commit = "git commit"
push   = "git push"
pull   = "git pull"
branches = "git branch -a"
```

They are named `recipes` and not `commands` on purpose. In this codebase
`commands.lua` means a module with `register()`/`unregister()` that owns a set
of *cdin commands*, and a table of strings would be a lie under that name.

Adding to it is a one-line change, and every menu entry and command that runs
that git invocation follows — which is why `vim-git`'s menu and its command
list cannot drift apart.

## How it works

**`api.lua` is not `init.lua`, and that is deliberate.** The extension manager
reads a plugin's `init.lua` with `dofile()`, which produces a *different* table
from the one `require` hands out. A plugin whose `init.lua` is also its public
API therefore ends up with two half-initialised copies, and whichever one a
consumer got depends on how it was loaded. So `init.lua` holds the manifest and
nothing else, and the real surface is `api.lua`, which is only ever `require`d.

This is worth internalising because it applies to every plugin in the catalog
and it is the one structural rule that has no `validate` check behind it.

**The editor has no idea git exists.** `core` exposes a generic hook,
`core.register_vcs_provider`, and the status bar reads through it. With no
provider registered the status bar renders nothing there. This is the same
arrangement as vim mode and the menu: the runtime is not allowed to grow a
special case for a capability it does not own.

**The provider is a table of three functions** — `is_ignored`,
`refresh_ignored_now`, and `status` — registered once and never removed, because
`core` keeps no list to remove from. `unregister()` drops this plugin's own
flag so a later enable registers again. That is a smaller promise than the rest
of the catalog makes, and it is honest about it.

**The second hook is the registry syncer.** Fetching the plugin catalog is a git
operation, so it lives here. `cdinx` needs to clone and pull but refuses to know
that git exists, so it asks for a syncer at bootstrap. With this plugin absent,
**Refresh Catalog** reports that it is unavailable instead of quietly doing
nothing — which is the behaviour you want from an operation that needs the
network.

**Status polling is a coroutine.** It sleeps `config.git_update_rate` between
passes and never blocks the frame loop. `is_ignored` is synchronous because the
file tree has to decide whether to draw an entry *now*, and it answers from a
cache that `refresh_ignored_now` updates.

## Files

| file | holds |
| --- | --- |
| `api.lua` | the public surface, and the two host hooks |
| `exec.lua` | running processes, platform differences |
| `status.lua` | the status table, polling, `.gitignore` |
| `recipes.lua` | the shared command strings |
| `manager/ops.lua` | cloning and pulling the catalog |
| `manager/find-git.lua` | finding the git executable |
| `manager/utils.lua` | shared helpers |
