# Contributing to cdin-x

## Two Ways to Contribute

### 1. Create a Plugin Locally (Personal)

```bash
make new-plugin my-awesome-plugin
```

The plugin is created in `X/<category>/my-awesome-plugin/`. Use cdin's Plugin Manager (`m` key) to install it.

### 2. Submit to Registry (Community)

```
X/<category>/my-plugin/
├── init.lua
├── manifest.lua
└── README.md
```

Open a PR to cdin-x. If approved, your plugin joins the catalog.

## Development Guidelines

1. **snake_case** everywhere — variables, functions, modules
2. **No globals at runtime** — all modules return tables
3. **Wrap external calls** with `pcall` or `core.try`
4. **Use coroutines** for background work (`core.add_thread`)
5. **Never block the frame loop** with synchronous I/O

## Commit Convention

All commits must follow conventional format:
- `feat(scope): description`
- `fix(scope): description`
- `docs(scope): description`
- `refactor(scope): description`
- `test(scope): description`
- `chore(scope): description`

## Submitting PRs

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-plugin`)
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

See [PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md) for the PR checklist.

## Quality

```bash
make fmt          # Format Lua code
make fmt-test     # Check formatting
make validate     # Validate project structure
make quality      # fmt-test + validate
make check        # CI equivalent
```

## Plugin Lifecycle

- **Draft** — in development, not in registry
- **Available** — in registry, ready for install
- **Deprecated** — installable but shows warning
- **Removed** — no longer available

## Need Help?

Open a Discussion or contact the maintainers.
