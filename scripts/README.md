# cdin-x Scripts

## Available Scripts

| Script | Description |
|--------|-------------|
| `new-plugin.lua` | Scaffold a new plugin |
| `plugin-list.lua` | List all plugins in X/ |
| `validate.lua` | Validate project structure |
| `generate-manifest.lua` | Generate manifest.lua |
| `install.sh` | Install cdin-x locally |

## Usage

```bash
# Create a new plugin
lua scripts/new-plugin.lua my-plugin languages

# List all plugins
lua scripts/plugin-list.lua

# Validate structure
lua scripts/validate.lua

# Generate manifest
lua scripts/generate-manifest.lua

# Install
bash scripts/install.sh local
```

## Adding a New Script

1. Create `scripts/<script-name>.lua`
2. Add to `psx.yml` custom.folders.scripts
3. Add to `.psx-project.yml`
4. Test with `make validate`
