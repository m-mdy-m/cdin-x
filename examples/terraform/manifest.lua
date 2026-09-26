-- examples/terraform/manifest.lua
return {
  name = "terraform",
  version = "1.0.0",
  description = "Terraform language support with syntax highlighting and LSP",
  author = "Your Name",
  license = "MIT",
  homepage = "https://github.com/m-mdy-m/cdin-x",
  path = "examples/terraform",
  tags = {"language", "terraform", "lsp", "infrastructure"},
  dependencies = {},
  config = {
    terraform_format_on_save = true,
    terraform_lsp_enabled = true,
    terraform_lsp_server = "terraform-lsp",
  },
  essential = false,
  min_cdin_version = "0.5.0",
  category = "languages",
}
