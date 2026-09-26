-- CDIN-X Plugin Manager UI.
local core    = require "core"
local command = require "core.input.command"
local Manager = require "core.x.manager"

local Command = {}

local CATEGORY_NAMES = {
  core="CORE", languages="LANGUAGES", lsp="LSP", formatters="FORMATTERS",
  git="GIT", debug="DEBUG", ui="UI", utils="UTILS",
  optional="OPTIONAL", themes="THEMES",
}
local CATEGORY_ORDER = {
  "core","languages","lsp","formatters","git","debug","ui","utils","optional","themes",
}

local function status(plugin)
  if plugin._source == "builtin" then return "[L]" end
  local s = Manager.get_status(plugin.name)
  if s == "installed" then return "[X]" end
  if s == "disabled" then return "[-]" end
  return "[ ]"
end

local function filter_text(text)
  return (text or ""):match("^%s*(.-)%s*$")
end

local function open_items(title, items, submit)
  core.command_view:enter(title, submit, function(text)
    local q = filter_text(text):lower()
    if q == "" then return items end
    local out = {}
    for _, item in ipairs(items) do
      if not item._header then
        if item.text:lower():find(q,1,true)
        or (item.info and item.info:lower():find(q,1,true)) then
          out[#out+1]=item
        end
      end
    end
    return out
  end)
end

local function catalog_items(include_builtins)
  Manager.ensure_registry(false)
  Manager.scan()

  local items={}
  local plugins=Manager.list()
  local by_category, seen_category = {}, {}
  for _, plugin in pairs(plugins) do
    if include_builtins or plugin._source ~= "builtin" then
      local cat=plugin.category or "other"
      by_category[cat] = by_category[cat] or {}
      by_category[cat][#by_category[cat]+1] = plugin
    end
  end

  local ordered_categories = {}
  for _, category in ipairs(CATEGORY_ORDER) do
    if by_category[category] then
      ordered_categories[#ordered_categories+1] = category
      seen_category[category] = true
    end
  end
  local extra = {}
  for category in pairs(by_category) do
    if not seen_category[category] then extra[#extra+1] = category end
  end
  table.sort(extra)
  for _, category in ipairs(extra) do ordered_categories[#ordered_categories+1] = category end

  for _, category in ipairs(ordered_categories) do
    local group=by_category[category]
    table.sort(group,function(a,b)return a.name<b.name end)
    items[#items+1]={text="── "..(CATEGORY_NAMES[category] or category:upper()).." ──",info="",_header=true}
    for _, plugin in ipairs(group) do
      items[#items+1]={
        text=string.format("%s %s",status(plugin),plugin.name),
        info=plugin.description,
        _plugin=plugin,
      }
    end
  end
  return items
end

function Command.show_menu()
  local items={
    {text="Extensions",info="Browse and install from the CDIN-X catalog",action=Command.show_catalog},
    {text="Installed",info="Manage installed extensions",action=Command.show_installed},
    {text="Search",info="Search the extension catalog",action=Command.show_search},
    {text="Install Local",info="Install an extension from a local directory",action=Command.show_install_local},
    {text="Update All",info="Re-fetch installed extensions whose registry version changed",action=Command.show_update_all},
    {text="Clean",info="Remove installed extensions no longer in the registry",action=Command.show_clean},
    {text="Refresh Catalog",info="Update the cdin-x catalog",action=Command.show_refresh},
  }
  open_items("CDIN-X",items,function(text,item)
    if item and item.action then item.action() end
  end)
end

function Command.show_catalog()
  local items=catalog_items(true)
  open_items("Extensions",items,function(text,item)
    if not item or not item._plugin then return end
    local plugin=item._plugin
    if plugin._source=="builtin" then
      Command.show_details(plugin.name)
      return
    end
    local st=Manager.get_status(plugin.name)
    if st=="installed" or st=="disabled" then
      Command.show_details(plugin.name)
    else
      local ok,err=Manager.install(plugin.name)
      if ok then core.log("Installed %s",plugin.name)
      else core.error("cdin-x: %s",err) end
    end
  end)
end

function Command.show_details(name)
  local plugin=Manager.get(name)
  if not plugin then return end
  local installed=Manager.get_status(name)=="installed"
  local disabled=Manager.get_status(name)=="disabled"

  local items={
    {text="Open README",info=plugin.description,action=function()
      local ok,err=Manager.open_readme(name)
      if not ok then core.error("cdin-x: %s",err) end
    end},
  }

  if plugin._source=="builtin" or plugin.essential then
    items[#items+1]={text="Locked",info="Built into CDIN and cannot be removed",action=function()
      core.log("%s is a built-in extension",name)
    end}
  elseif installed or disabled then
    items[#items+1]={text=disabled and "Enable" or "Disable",
      info=disabled and "Load on this and future sessions" or "Stop loading without uninstalling",
      action=function()
        local ok,err
        if disabled then ok,err=Manager.enable(name) else ok,err=Manager.disable(name) end
        if not ok then core.error("cdin-x: %s",err) else core.log("%s updated",name) end
      end}
    items[#items+1]={text="Update",info="Re-fetch from the registry if a newer version exists",
      action=function()
        local ok,result=Manager.update(name)
        if ok and #result.updated>0 then core.log("Updated %s",name)
        elseif ok then core.log("%s is already up to date",name)
        else core.error("cdin-x: %s",result.errors and table.concat(result.errors,"; ") or "update failed") end
      end}
    items[#items+1]={text="Uninstall",info="Remove the installed extension",
      action=function()
        local ok,err=Manager.uninstall(name)
        if not ok then core.error("cdin-x: %s",err) else core.log("Uninstalled %s",name) end
      end}
  else
    items[#items+1]={text="Install",info="Copy into the local extension store",
      action=function()
        local ok,err=Manager.install(name)
        if not ok then core.error("cdin-x: %s",err) else core.log("Installed %s",name) end
      end}
  end

  items[#items+1]={text="Back",info="",action=Command.show_catalog}
  open_items(name.."  "..plugin.version,items,function(text,item)
    if item and item.action then item.action() end
  end)
end

function Command.show_installed()
  Manager.scan()
  local items={}
  local local_plugins=Manager.list_local()
  local names={}
  for name in pairs(local_plugins) do names[#names+1]=name end
  table.sort(names)
  for _,name in ipairs(names) do
    local plugin=local_plugins[name]
    items[#items+1]={text=string.format("%s %s",status(plugin),name),info=plugin.description,_plugin=plugin}
  end
  if #items==0 then items[1]={text="No installed extensions",info="Use Extensions to browse the catalog"} end
  open_items("Installed",items,function(text,item)
    if item and item._plugin then Command.show_details(item._plugin.name) end
  end)
end

function Command.show_search()
  core.command_view:enter("Search CDIN-X",function(text,item)
    if item and item._plugin then Command.show_details(item._plugin.name) end
  end,function(text)
    local results=Manager.search(filter_text(text))
    local items={}
    for _,p in pairs(results) do
      items[#items+1]={text=status(p).." "..p.name,info=p.description,_plugin=p}
    end
    table.sort(items,function(a,b)return a.text<b.text end)
    return items
  end)
end

function Command.show_install_local()
  core.command_view:enter("Install local extension path",function(path)
    path=filter_text(path)
    if path=="" then return end
    local ok,err=Manager.install_local(path)
    if not ok then core.error("cdin-x: %s",err) else core.log("Installed local extension") end
  end,function(text)
    return require("core.utils.common").path_suggest(text or "")
  end)
end

function Command.show_update_all()
  local ok,result=Manager.update()
  if #result.updated>0 then
    core.log("cdin-x: updated %s",table.concat(result.updated,", "))
  else
    core.log("cdin-x: everything installed is already up to date")
  end
  if not ok then
    core.error("cdin-x: %s",table.concat(result.errors,"; "))
  end
end

function Command.show_clean()
  local ok,orphaned=Manager.clean(true)
  if not ok then core.error("cdin-x: %s",tostring(orphaned)); return end
  if #orphaned==0 then
    core.log("cdin-x: nothing to clean — no orphaned installed extensions")
    return
  end

  local items={}
  items[#items+1]={text=string.format("Remove %d orphaned extension(s)",#orphaned),
    info=table.concat(orphaned,", "),
    action=function()
      local rok,result=Manager.clean(false)
      if #result.removed>0 then core.log("cdin-x: removed %s",table.concat(result.removed,", ")) end
      if not rok then core.error("cdin-x: %s",table.concat(result.errors,"; ")) end
    end}
  items[#items+1]={text="Cancel",info="",action=function() core.log("cdin-x: clean cancelled") end}
  open_items("Clean CDIN-X",items,function(text,item)
    if item and item.action then item.action() end
  end)
end

function Command.show_refresh()
  local ok,err=Manager.refresh_registry()
  if ok then
    core.log("cdin-x catalog refreshed")
    Command.show_catalog()
  else
    core.error("cdin-x: %s",err)
  end
end

function Command.register()
  command.add(nil,{
    ["cdin-x:menu"]=Command.show_menu,
    ["pluginmanager:menu"]=Command.show_menu,
    ["cdin-x:catalog"]=Command.show_catalog,
    ["cdin-x:update"]=Command.show_update_all,
    ["cdin-x:clean"]=Command.show_clean,
    ["cdin-x:refresh"]=Command.show_refresh,
  })
end

return Command
