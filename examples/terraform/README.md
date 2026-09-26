# terraform

Terraform language support for cdin.

## Description

This plugin provides:
- Terraform syntax highlighting
- `terraform fmt` integration (format on save)
- `terraform validate` linting
- LSP client support

## Installation

Install from cdin using the Plugin Manager (`m` key).

Or manually copy to `X/languages/terraform/`.

## Usage

Commands available after installation:

| Command | Keybinding | Description |
|---------|-----------|-------------|
| `terraform:format` | `Ctrl+Shift+F` | Format document with `terraform fmt` |
| `terraform:lint` | `Ctrl+Shift+V` | Validate with `terraform validate` |
| `terraform:show-docs` | — | Open Terraform documentation |

## Configuration

Add to `data/user/init.lua`:

```lua
config.terraform_format_on_save = true
config.terraform_lsp_enabled = true
config.terraform_lsp_server = "terraform-lsp"
```

## Contributing

To submit this plugin to the cdin-x registry:
1. Create a PR with this directory under `X/languages/terraform/`
2. Maintainers review and approve
3. Plugin joins the catalog

## License

MIT
