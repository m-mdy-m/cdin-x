local core = require "core"

local M = {
  menus = {},
}

local seq = 0

local function normalize_sections(value)
  if not value then return {} end
  if value.header or value.key or value.action then return { value } end
  return value
end

local function build_items(entries)
  local items = {}
  for i, item in ipairs(entries or {}) do
    if item.header then
      items[#items + 1] = {
        text = "  ── " .. (item.header or "") .. " ──",
        info = "",
        _key = nil,
        _action = nil,
        _is_header = true,
      }
      for j, e in ipairs(item.entries or {}) do
        items[#items + 1] = {
          text = (j == #item.entries and "└─ " or "├─ ")
              .. "[" .. (e.key or "?") .. "] "
              .. ((e.icon and e.icon ~= "") and (e.icon .. " ") or "")
              .. (e.label or ""),
          info = e.info,
          _key = e.key,
          _action = e.action,
        }
      end
    else
      items[#items + 1] = {
        text = "[" .. (item.key or "?") .. "] " .. (item.label or item.text or ""),
        info = item.info,
        _key = item.key,
        _action = item.action,
      }
    end
  end
  return items
end

local function collect_action_items(items)
  local out = {}
  for _, item in ipairs(items) do
    if item._action then out[#out + 1] = item end
  end
  return out
end

local function key_map(items)
  local map = {}
  for _, item in ipairs(items) do
    if item._key and item._action then map[item._key] = item._action end
  end
  return map
end

local function open_prompt(title, entries)
  local items = build_items(entries)
  local actions = collect_action_items(items)
  local keys = key_map(items)

  core.command_view:enter(title .. "  (key / ↑↓ / Tab)", function(text, item)
    if item and item._action then
      item._action(); return
    end
    local t = text:match("^%s*(.-)%s*$")
    if t == "" then return end
    local action = keys[t:sub(1, 1)]
    if action then action(); return end
    local lo = t:lower()
    for _, candidate in ipairs(actions) do
      if candidate.text:lower():find(lo, 1, true)
        or (candidate.info and candidate.info:lower():find(lo, 1, true)) then
        candidate._action(); return
      end
    end
    core.error("menu: unknown option '%s'", text)
  end, function(text)
    local t = text:match("^%s*(.-)%s*$")
    if t == "" then return items end
    local key = t:sub(1, 1)
    if keys[key] then
      for _, item in ipairs(items) do
        if item._key == key then return { item } end
      end
    end
    local lo = t:lower()
    local result = {}
    for _, item in ipairs(items) do
      if item._action and (item.text:lower():find(lo, 1, true)
          or (item.info and item.info:lower():find(lo, 1, true))) then
        result[#result + 1] = item
      end
    end
    return result
  end)
end

function M.define(name, spec)
  M.menus[name] = {
    spec = spec or {},
    providers = {},
    contexts = {},
  }
end

function M.extend(name, id, provider, order)
  local menu = M.menus[name]
  assert(menu, "menu is not defined: " .. tostring(name))
  seq = seq + 1
  menu.providers[id] = { fn = provider, order = order or 100, seq = seq }
end

function M.remove_extension(name, id)
  local menu = M.menus[name]
  if menu then menu.providers[id] = nil end
end

function M.set_context_provider(name, id, provider, priority)
  local menu = M.menus[name]
  assert(menu, "menu is not defined: " .. tostring(name))
  seq = seq + 1
  menu.contexts[id] = { fn = provider, priority = priority or 100, seq = seq }
end

function M.remove_context_provider(name, id)
  local menu = M.menus[name]
  if menu then menu.contexts[id] = nil end
end

function M.open(name, override_context)
  local menu = M.menus[name]
  if not menu then
    core.error("menu: unknown menu '%s'", name)
    return false
  end

  local context
  if override_context ~= nil then
    context = override_context
  else
    local contexts = {}
    for _, item in pairs(menu.contexts) do contexts[#contexts + 1] = item end
    table.sort(contexts, function(a, b)
      if a.priority == b.priority then return a.seq > b.seq end
      return a.priority > b.priority
    end)
    for _, item in ipairs(contexts) do
      context = item.fn()
      if context ~= nil then break end
    end
    if context == nil and menu.spec.context then context = menu.spec.context() end
  end

  local entries = {}
  if menu.spec.entries then
    for _, section in ipairs(normalize_sections(menu.spec.entries(context) or {})) do
      entries[#entries + 1] = section
    end
  end

  local providers = {}
  for _, item in pairs(menu.providers) do providers[#providers + 1] = item end
  table.sort(providers, function(a, b)
    if a.order == b.order then return a.seq < b.seq end
    return a.order < b.order
  end)
  for _, item in ipairs(providers) do
    for _, section in ipairs(normalize_sections(item.fn(context) or {})) do
      entries[#entries + 1] = section
    end
  end

  local title = menu.spec.title or name
  local ctx_label = ""
  if type(context) == "table" then ctx_label = context.label or context.name or "" end
  if ctx_label ~= "" then title = title .. "  " .. ctx_label end
  open_prompt(title, entries)
  return true
end

return M
