# odin-standards

[![CI](https://github.com/alexisbcz/odin-standards/actions/workflows/ci.yml/badge.svg)](https://github.com/alexisbcz/odin-standards/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Shared rules, templates and CI for every `alexisbcz` Odin library.

## What's here

| Path | Purpose |
| --- | --- |
| [STANDARDS.md](STANDARDS.md) | The rules: layout, naming, allocators, errors, docs, versioning, commits |
| [ROADMAP.md](ROADMAP.md) | Which libraries Odin needs to replace Go, TypeScript and Swift, in order |
| [`templates/`](templates) | A complete, working library skeleton to copy into a new repository |
| [`templates/.github/workflows/ci.yml`](templates/.github/workflows/ci.yml) | CI for Linux and macOS: check, test, build examples, lint prose |
| [`templates/.github/styles/OdinDocs`](templates/.github/styles/OdinDocs) | The Vale style that every README must pass |

## Start a new library

```sh
git clone https://github.com/alexisbcz/odin-standards
cp -R odin-standards/templates/. mylib/
cd mylib
git init -b main
```

Then rename `mylib` in file names, package names, the README, the changelog links and `.github/styles/config/vocabularies/Odin/accept.txt`, and check that everything passes:

```sh
vale sync
odin check . -vet -strict-style -disallow-do -no-entry-point
odin test tests -vet -strict-style -disallow-do
odin run examples/basic
vale *.md
```

## How this repository tests itself

CI runs the template's own workflow steps against `templates/`, so the skeleton library, its tests, its example and the pinned Odin install step stay green. Vale lints every Markdown file in the repository with the same style the templates ship.

## Contributing

Propose changes to the standards in a pull request that also updates the templates, so the two never drift. Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with bullet-point bodies, as [STANDARDS.md](STANDARDS.md#commits) describes.

## License

MIT. See [LICENSE](LICENSE).
