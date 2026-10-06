-- The manifest for the git package. Data only: no require, no functions.
return {
  name = "git",
  kind = "plugin",
  version = "0.2.0",
  description = "Git status, ignore rules and shared shell recipes",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "git", "vcs", "status" },

  category = "core",
  min_cdin_version = "0.5.0",
  needs = { executables = { "git" } },

  -- Git status badges in the project file tree. Runs only while treeview is
  -- loaded too, and this package being up is the other half of that condition --
  -- see the file for why one key is enough.
  with = {
    treeview = "with/treeview.lua",
  },

  entry = "init.lua",
}