# Getting Started with cdin-x

`cdin-x` is the extension ecosystem for CDIN. It keeps optional functionality out of
the editor installation and gives users a local extension store, registry metadata,
and an in-editor manager.

## Structure

```text
core/       runtime manager and API copied into CDIN/data/core/x/
X/          official extension sources
registry/   generated catalog metadata
templates/  extension scaffolds
docs/       documentation
scripts/    validation and registry tools
```

## Create your first extension

```bash
lua scripts/new-plugin.lua my-first-plugin utils
```

This creates:

```text
X/utils/my-first-plugin/
├── init.lua
├── manifest.lua
└── README.md
```

## Install locally

Start CDIN, press `m`, choose **Extensions**, then **Install Local** and point it at the
extension directory.

The extension is copied into the external user extension store before it is loaded.

## Publish it

Move the extension into the appropriate `X/<category>/` directory in `cdin-x`, run the
lightweight validation/registry generation, and open a PR. Once accepted, the extension
appears in the catalog used by CDIN.

## Core rule

Keep the runtime small. If a feature can be an extension, prefer making it an extension.
Only functionality required to boot and edit files should live in CDIN core or the
built-in `X/core` bundle.
