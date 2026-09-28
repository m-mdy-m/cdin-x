-- Vim's normal- and visual-mode key handling.
--
-- This file owns only *vim's own* vocabulary: motions, the i/a/o entry
-- points, operators (d, y, c), counts, and the g/d/y/c two-key
-- sequences. Every key that belongs to some other plugin is looked up in
-- the registry (X.core.vim.registry) after vim's own keys have declined
-- it, which is why there is no `if k == "/"` or `if k == "m"` here any
-- more:
--
--   / n N *        -> vim-search        (registry.call_key)
--   m              -> vim-menu          (registry.call_key)
--   shift+m        -> vim-plugin-manager(registry.call_key)
--   tab            -> vim-window        (registry.call_key)
--   gt / gT        -> vim-tab           (registry.call_gmap)
--   ctrl+w {c}     -> vim-window        (registry.wmap_get)
--
-- Keys reach the plugin registry as a token ("m", "shift+m") rather than a
-- raw key plus a separate shift flag, so an integration never has to
-- guess which modifier was held.
local core      = require "core"
local config    = require "core.config"
local command   = require "core.input.command"
local keymap    = require "core.input.keymap"
local registry  = require "X.core.vim.registry"
local exline    = require "X.core.vim.ex.commandline"
local mode      = require "X.core.vim.vimode.mode"
local motions   = require "X.core.vim.vimode.motions"

local M = {}

-- How long a first key of a two-key sequence (g, d, y, c) stays live.
local PENDING_TIMEOUT = 0.6

local pending   = nil   -- { key = "g"|"d"|"y"|"c"|"ctrl_w", t = <time> }
local count_buf = ""    -- digits typed before gt, e.g. the "3" in "3gt"

local function is_double(key)
  return pending
      and pending.key == key
      and system.get_time() - pending.t < PENDING_TIMEOUT
end

local function start_sequence(key)
  pending = { key = key, t = system.get_time() }
end

local function abandon_sequence(key)
  if pending and pending.key ~= key and pending.key ~= "ctrl_w" then
    pending = nil
    count_buf = ""
  end
end

-- Drop any half-typed state. Used when leaving insert mode and on unload.
function M.reset()
  pending = nil
  count_buf = ""
end

-- ── the two-key sequences ───────────────────────────────────────────────
local function resolve_double(view, k, shift)
  if k == "g" then
    if is_double("g") then
      pending = nil
      command.perform("doc:move-to-start-of-doc")
      return true
    end
    start_sequence("g")
    return true
  end

  if k == "d" or k == "y" or k == "c" then
    if is_double(k) then
      pending = nil
      if k == "d" then
        command.perform("doc:delete-lines")
      elseif k == "y" then
        command.perform("doc:select-lines")
        command.perform("doc:copy")
        command.perform("doc:select-none")
      else -- c
        command.perform("doc:delete-lines")
        mode.set(view, mode.INSERT)
      end
      return true
    end
    start_sequence(k)
    return true
  end

  return false
end

-- ── shift + lowercase, i.e. vim's capitalised keys ───────────────────────
local function resolve_shifted(view, k, count)
  if     k == "g" then command.perform("doc:move-to-end-of-doc")
  elseif k == "i" then
    command.perform("doc:move-to-start-of-line")
    mode.set(view, mode.INSERT)
  elseif k == "a" then
    command.perform("doc:move-to-end-of-line")
    mode.set(view, mode.INSERT)
  elseif k == "o" then
    command.perform("doc:move-to-start-of-line")
    command.perform("doc:newline-above")
    mode.set(view, mode.INSERT)
  elseif k == "4" then command.perform("doc:move-to-end-of-line")   -- $
  elseif k == "6" then command.perform("doc:move-to-start-of-line") -- ^
  elseif k == "d" then -- D: delete to end of line
    command.perform("doc:select-to-end-of-line")
    command.perform("doc:cut")
  elseif k == "j" then -- J: join with the next line
    command.perform("doc:move-to-end-of-line")
    command.perform("doc:delete")
  end
  count()
end

-- ── visual mode ─────────────────────────────────────────────────────────
-- Vim's own visual keys first, then the plugin registry, so an
-- integration can add a visual key without shadowing a normal-mode one.
local function handle_visual(view, token, shift)
  if not shift then
    if token == "d" or token == "x" then
      command.perform("doc:cut")
      mode.set(view, mode.NORMAL)
      return true
    elseif token == "y" then
      command.perform("doc:copy")
      command.perform("doc:select-none")
      mode.set(view, mode.NORMAL)
      return true
    elseif token == ">" then
      command.perform("doc:indent")
      return true
    elseif token == "<" then
      command.perform("doc:unindent")
      return true
    end
  end

  if registry.call_visual_key(token, view) then return true end

  local motion = motions.command_for(token, true)
  if motion then
    command.perform(motion)
    return true
  end

  return false
end

-- ── the Ctrl+W prefix ───────────────────────────────────────────────────
local function arm_ctrl_w(view)
  if view and mode.get(view) == mode.INSERT then return false end
  pending   = { key = "ctrl_w", t = system.get_time() }
  count_buf = ""
  return true
end

-- ── normal mode ─────────────────────────────────────────────────────────
local function handle_normal(view, k, token, shift)
  if not shift and k:match("^%d$") and (k ~= "0" or count_buf ~= "") then
    count_buf = count_buf .. k
    return true
  end

  if pending and pending.key == "ctrl_w" then
    pending   = nil
    count_buf = ""
    local wcmd = registry.wmap_get(k)
    if wcmd then command.perform(wcmd) end
    return true
  end

  -- g + {t,T}: resolved generically. vimode never learns that "t" means
  -- "switch tab"; it only knows the sequence is two keys long.
  if pending and pending.key == "g" then
    if k == "t" then
      pending = nil
      local n = tonumber(count_buf)
      count_buf = ""
      if shift then
        registry.call_gmap("gT")
      else
        registry.call_gmap("gt", n)
      end
      return true
    end
  end

  if not shift and resolve_double(view, k) then return true end

  abandon_sequence(k)

  if shift then
    resolve_shifted(view, k, function() count_buf = "" end)
    return true
  end

  local motion = motions.command_for(k, false)
  if motion then
    command.perform(motion)
    return true
  end

  if k == "v" then
    if mode.get(view) == mode.VISUAL then
      command.perform("doc:select-none")
      mode.set(view, mode.NORMAL)
    else
      mode.set(view, mode.VISUAL)
    end
    return true
  end

  if k == "i" then mode.set(view, mode.INSERT); return true end

  if k == "a" then
    command.perform("doc:move-to-next-char")
    mode.set(view, mode.INSERT)
    return true
  end

  if k == "o" then
    command.perform("doc:move-to-end-of-line")
    command.perform("doc:newline")
    mode.set(view, mode.INSERT)
    return true
  end

  if k == "0" then command.perform("doc:move-to-start-of-line"); return true end

  if k == "x" then
    command.perform("doc:select-to-next-char")
    command.perform("doc:cut")
    return true
  end

  if k == "p" then command.perform("doc:paste"); return true end
  if k == "u" then command.perform("doc:undo"); return true end
  if k == "r" then command.perform("doc:redo"); return true end

  if registry.call_key(token, view) then return true end

  if #k == 1 then return true end

  return false
end

-- ── entry point ─────────────────────────────────────────────────────────
function M.handle_key(k)
  if not config.vim_mode_enabled then return false end

  if core.active_view == core.command_view then
    if k == "up" and keymap.modkeys.ctrl then return exline.history_prev() end
    if k == "down" and keymap.modkeys.ctrl then return exline.history_next() end
    return false
  end

  -- Ctrl+W is armed *before* the ctrl/alt guard below, because that guard
  if k == "ctrl+w" and arm_ctrl_w(core.active_docview()) then
    return true
  end

  if k:find("ctrl") or k:find("alt") then return false end
  if keymap.modkeys.ctrl or keymap.modkeys.alt or keymap.modkeys.altgr then
    return false
  end

  local shift  = keymap.modkeys.shift
  local token  = shift and ("shift+" .. k) or k

  if shift and k == ";" then
    exline.open()
    return true
  end

  local view = core.active_docview()

  if not view then
    return registry.call_key(token, nil) or false
  end

  if k == "escape" then
    M.reset()   -- drop any half-typed sequence and count
    if mode.get(view) == mode.INSERT then
      mode.set(view, mode.NORMAL)
      command.perform("doc:move-to-previous-char")
    elseif mode.get(view) == mode.VISUAL then
      mode.set(view, mode.NORMAL)
      command.perform("doc:select-none")
    else
      command.perform("doc:select-none")
    end
    return true
  end

  local current = mode.get(view)

  if current == mode.INSERT then
    return false
  end

  if current == mode.VISUAL then
    if handle_visual(view, token, shift) then return true end
    -- Unclaimed visual-mode keys fall through to normal handling, which
    -- is how "gg" and friends keep working while a selection is active.
  end

  return handle_normal(view, k, token, shift)
end

return M
