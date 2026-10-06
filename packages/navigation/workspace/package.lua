-- The manifest for the workspace package. Data only: no require, no functions.
--
-- Tabs, windows and sessions, which are three views of one thing: what the editor
-- has open. They are one package because a user who closes tabs also closes
-- windows and saves sessions, and splitting them would mean three packages whose
-- features can only be switched on together.
return {
  name = "workspace",
  kind = "plugin",
  version = "0.2.0",
  description = "Tabs, window splits and persistent session restore",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "ui", "tabs", "windows", "state" },

  category = "core",
  min_cdin_version = "0.5.0",

  features = {
    tab = {
      default = true,
      description = "Tab management: new, close, reorder, and go to a tab by number",
    },
    window = {
      default = true,
      description = "Window splits, focus movement and layout sizing",
    },
    session = {
      default = true,
      description = "Restore open files, project and theme on start",
    },
    ["tab-session"] = {
      default = true,
      description = "Include the open tabs in the saved session",
    },
  },

  -- Each member keeps its own directory and its own modules; `tab-session` needs
  -- both tab and session, which inside one package is a feature ordering rather
  -- than a declared dependency.
  entry = "init.lua",
}