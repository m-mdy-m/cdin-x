# X — CDIN-X Extension Catalog

Every catalog entry is self-contained:

```text
X/<category>/<name>/
├── init.lua
├── manifest.lua
├── README.md
└── implementation modules...
```

The plugin manifest is the source of truth. The catalog is scanned at runtime; no
central runtime registry database is required.
