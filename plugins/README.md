# plugins

One directory, one file, one job: to be found.

```text
plugins/cdin-x/init.lua
```

cdin's loader walks this directory looking for entry points. This is the one
that starts the manager, which is why the manager is a *site* plugin rather
than something the editor reaches for on its own — the editor has no idea
plugins exist, and this file is how it finds out.

It deliberately does not touch `package.path`. The host has already appended
the site roots by the time any plugin's `init()` runs, so doing it again here
would be two answers to the same question.
