local scan = dofile("scripts/_scan.lua")

print(string.format("\n%-25s %-15s %-40s %s", "NAME", "CATEGORY", "DESCRIPTION", "VERSION"))
print(string.rep("-", 105))

local total = 0
for _, entry in ipairs(scan.plugin_entries()) do
  local meta = entry.meta
  if meta.name then
    local desc = (meta.description or "N/A"):sub(1, 38)
    local ver  = meta.version or "N/A"
    local ess  = meta.essential and " [ESSENTIAL]" or ""
    print(string.format("  %-23s %-15s %-40s %s%s",
      meta.name, meta.category or entry.category, desc, ver, ess))
    total = total + 1
  end
end

print(string.format("\nTotal: %d extensions\n", total))
