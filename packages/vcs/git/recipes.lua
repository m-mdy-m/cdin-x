-- Shell recipes for common git operations.
--
-- These are command *strings*, not cdin commands: nothing registers them
-- and nothing binds a key to them. They exist so every package that runs git
-- shares one spelling of each invocation instead of each hardcoding its own.
-- See `vim`'s `with/git.lua` entry, which runs every one of them through
-- vim.shell.run_in_buffer().
--
-- Named `recipes` rather than `commands` on purpose: in this codebase
-- `commands.lua` means "a module with register()/unregister() that owns a
-- set of cdin commands", and a static table of shell strings would be
-- misleading under that name.
return {
  status  = "git status",
  log     = "git log --oneline -20",
  diff    = "git diff",
  add_all = "git add .",
  commit  = "git commit",
  push    = "git push",
  pull    = "git pull",
  branches = "git branch -a",
}
