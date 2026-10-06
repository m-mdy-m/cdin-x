local M = {
  _view = nil,
  _badge = {},
  _refresh = {},
}

function M.set_view(view)
  M._view = view
end

function M.get_view()
  return M._view
end

function M.register_badge_provider(id, provider, order)
  M._badge[id] = { fn = provider, order = order or 100 }
end

function M.remove_badge_provider(id)
  M._badge[id] = nil
end

function M.get_badge(item)
  local providers = {}
  for _, item in pairs(M._badge) do providers[#providers + 1] = item end
  table.sort(providers, function(a, b) return a.order < b.order end)
  for _, provider in ipairs(providers) do
    local label, color = provider.fn(item)
    if label then return label, color end
  end
  return nil, nil
end

function M.register_refresh_provider(id, provider)
  M._refresh[id] = provider
end

function M.remove_refresh_provider(id)
  M._refresh[id] = nil
end

function M.refresh_providers()
  for _, provider in pairs(M._refresh) do
    pcall(provider)
  end
end

return M
