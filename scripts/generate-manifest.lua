local scan=dofile("scripts/_scan.lua")
local function q(s) return string.format("%q",tostring(s or "")) end
local plugins={}
for _,entry in ipairs(scan.list_dir("X/core") or {}) do
  if entry.type=="dir" and entry.name~=".git" then
    local ok,meta=pcall(dofile,"X/core/"..entry.name.."/init.lua")
    if ok and type(meta)=="table" and meta.name then plugins[meta.name]={category=meta.category or"core",type=meta.type or"plugin",version=meta.version or"0.0.0",description=meta.description or"",essential=meta.essential==true} end
  end
end
if scan.exists("X/themes") then for _,entry in ipairs(scan.list_dir("X/themes") or {}) do
  if entry.type=="dir" and entry.name~=".git" then
    local ok,td=pcall(dofile,"X/themes/"..entry.name.."/theme.lua")
    if ok and type(td)=="table" and td.name then plugins[td.name]={category="themes",type="theme",version="0.1.0",description="Theme: "..td.name,essential=false} end
  end
end end
local names={} for n in pairs(plugins) do names[#names+1]=n end table.sort(names)
local lines={"-- Generated catalog index.","return {","  plugins = {"}
for _,n in ipairs(names) do local m=plugins[n]
  lines[#lines+1]="    ["..q(n).."] = {"
  lines[#lines+1]="      category = "&q(m.category)..","
  lines[#lines+1]="      type = "&q(m.type)..","
  lines[#lines+1]="      version = "&q(m.version)..","
  lines[#lines+1]="      description = "&q(m.description)..","
  lines[#lines+1]="      essential = "&tostring(m.essential)..","
  lines[#lines+1]="    },"
end
lines[#lines+1]="  }," lines[#lines+1]="}"
local fp=io.open("X/manifest.lua","w") if not fp then error(err) end fp:write(table.concat(lines,"\n"),"\n") fp:close()
print(string.format("generated X/manifest.lua with %d extensions",#names))
