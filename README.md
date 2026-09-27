# cdin-x

**cdin-x** is the extension ecosystem for [cdin](https://github.com/m-mdy-m/cdin).
It is deliberately separate from the editor runtime: cdin ships only its core runtime
and a small set of mandatory built-in extensions, while optional extensions live here
and are installed per-user.

![cdin-x](assets/CDIN-X.png)

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-orange.svg)](CHANGELOG.md)

---

## What it is

cdin-x is the extension ecosystem for the cdin text editor. It keeps optional functionality
out of the editor installation and gives users a local extension store, registry metadata,
and an in-editor manager.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Documentation

- [Getting Started](docs/getting-start.md) — quick start guide
- [Architecture](docs/architecture/README.md) — system architecture and plugin lifecycle
- [API](docs/api/README.md) — core module API reference
- [Development](docs/development/README.md) — how to develop and submit extensions
- [Installation](docs/INSTALLATION.md) — detailed installation instructions

## License

MIT — see [LICENSE](LICENSE).
