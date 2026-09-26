local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end;return false end
local e={}
for _,p in ipairs({"README.md","core/init.lua","core/manager.lua","core/config.lua","core/command.lua","scripts/new-plugin.lua"}) do if not exists(p) then table.insert(e,p.." not found") end end
if not exists("fonts") then table.insert(e,"fonts/ not found")
else for _,f in ipairs({"font.ttf","monospace.ttf","icons.ttf"}) do if not exists("fonts/"..f) then table.insert(e,"fonts/"..f.." not found") end end end
for _,n in ipairs({"core","autocomplete","autoreload","autoupdate","projectsearch","session","trimwhitespace","vim","treeview","tab","window"}) do if not exists("X/core/"..n.."/init.lua") then table.insert(e,"X/core/"..n.."/init.lua not found") end end
if exists("X/themes") then local h=io.popen('ls -d X/themes/*/ 2>/dev/null') if h then for d in h:lines() do local nm=d:match("[^/]+/$") if nm and nm~=".git" and not exists(d.."theme.lua") then table.insert(e,d.."theme.lua not found") end end h:close() end
else table.insert(e,"X/themes/ not found") end
if #e>0 then print("cdin-x validation failed:");for _,err in ipairs(e) do print("  - "..err) end;os.exit(1) end
print("cdin-x structure valid")
