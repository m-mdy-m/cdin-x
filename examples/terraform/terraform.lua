-- examples/terraform/terraform.lua
-- Example: Terraform Language Plugin
-- This shows how to create a language plugin for cdin-x.
--
-- To use this plugin:
--   1. Copy this directory to X/languages/terraform/
--   2. Add init.lua and manifest.lua
--   3. Install via Plugin Manager (m key)
--   4. Or submit a PR to cdin-x to join the registry

local M = {}

-- ═══════════════════════════════════════════════
-- REQUIRED: Plugin metadata
-- ═══════════════════════════════════════════════

M.name = "terraform"
M.version = "1.0.0"
M.description = "Terraform language support with syntax highlighting and LSP"
M.author = "Your Name"
M.license = "MIT"

-- ═══════════════════════════════════════════════
-- REQUIRED: Plugin dependencies
-- ═══════════════════════════════════════════════
-- Other plugins this plugin depends on.
-- Empty table means no dependencies.

M.dependencies = {}

-- ═══════════════════════════════════════════════
-- REQUIRED: Default configuration
-- ═══════════════════════════════════════════════
-- These values can be overridden by the user in data/user/init.lua

M.config = {
  terraform_format_on_save = true,
  terraform_lsp_enabled = true,
  terraform_lsp_server = "terraform-lsp",
  terraform_lsp_path = "terraform-lsp",
}

-- ═══════════════════════════════════════════════
-- REQUIRED: Plugin metadata
-- ═══════════════════════════════════════════════

M.essential = false
M.min_cdin_version = "0.5.0"
M.tags = {"language", "terraform", "lsp", "infrastructure"}
M.category = "languages"

-- ═══════════════════════════════════════════════
-- MANDATORY: init() — Called when plugin loads
-- ═══════════════════════════════════════════════
-- Use this to register commands, keymaps, views,
-- and start background threads.

function M.init(core, config)
  local command = require "core.input.command"
  local keymap  = require "core.input.keymap"

  -- Register commands
  command.add(nil, {
    ["terraform:format"] = function()
      -- Format the current document with terraform fmt
      core.log("Terraform: formatting document...")
      -- Implementation: run terraform fmt
    end,
    ["terraform:lint"] = function()
      -- Run terraform validate
      core.log("Terraform: validating...")
    end,
    ["terraform:show-docs"] = function()
      -- Show Terraform documentation
      core.log("Opening Terraform docs...")
    end,
  })

  -- Register keymaps
  keymap.add({
    ["ctrl+shift+f"] = "terraform:format",
    ["ctrl+shift+v"] = "terraform:lint",
  })

  -- Start LSP client if enabled
  if config.terraform_lsp_enabled then
    M.start_lsp(core, config)
  end

  core.log("✓ Terraform plugin loaded")
end

-- ═══════════════════════════════════════════════
-- OPTIONAL: start_lsp() — Start Language Server
-- ═══════════════════════════════════════════════
-- This shows how to start a background LSP client
-- using coroutines (core.add_thread).

function M.start_lsp(core, config)
  core.add_thread(function()
    while true do
      -- LSP client loop
      -- Communicate with terraform-lsp server
      coroutine.yield(1)  -- Check every second
    end
  end)
end

-- ═══════════════════════════════════════════════
-- MANDATORY: unload() — Called when plugin is removed
-- ═══════════════════════════════════════════════
-- Clean up: remove commands, keymaps, threads, views.

function M.unload()
  core.log("Terraform plugin unloaded")
  -- Remove commands, keymaps, stop LSP client
end

return M
