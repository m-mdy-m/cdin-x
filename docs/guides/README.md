# Guides

## Plugin Manager Usage

### Open Plugin Manager

Press `m` in cdin.

### Menu Options

- **📦 All Plugins** — View all available plugins
- **⬇️ Install** — Install a new plugin
- **🗑️ Uninstall** — Remove a plugin
- **🔍 Search** — Search plugins by name or description

### Essential Plugins

Cannot be uninstalled: core, vim, tab, window, treeview.

### Enabling/Disabling

Optional plugins can be toggled via `config.plugins[name] = true/false` in `the external user configuration`.

## Creating Plugins

See [Development](development/README.md).

## Configuration

```lua
-- the external user configuration
config.plugins = {
  my_plugin = true,
  other_plugin = false,
}
config.plugin_install_path = EXEDIR .. "/the user extension storelocal"
config.plugins_enabled_by_default = true
```

## Submitting to Registry

See [Development](development/README.md#submitting-to-registry).
