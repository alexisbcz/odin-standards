# Standards for alexisbcz Odin libraries

Every library under the `alexisbcz` GitHub account follows these rules. They exist so that a user who learned one library already knows how the next one feels: where the files live, who frees what, and how errors come back.

The rules are concrete on purpose. When a rule and your taste disagree, follow the rule and open an issue here.

## Package layout

The repository root is the package. Users import the repository directory itself, so there is no `src/` folder.

```text
mylib/
├── mylib.odin            # Package doc comment and core API
├── parse.odin            # More files of the same package, named by topic
├── tests/
│   └── mylib_test.odin   # package mylib_tests, run with `odin test tests`
├── examples/
│   └── basic/
│       └── main.odin     # package main, run with `odin run examples/basic`
├── .github/
│   ├── styles/           # Vale styles: OdinDocs and the Odin vocabulary
│   └── workflows/ci.yml
├── .editorconfig
├── .gitignore
├── .vale.ini
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

- Every `.odin` file in the root declares the same `package mylib`.
- Put the package doc comment, a `/* */` block directly above `package mylib`, in the file named after the package.
- `tests/` is its own package, named `mylib_tests`, that imports the library with `import mylib ".."`. Tests only see the public API, which keeps the API honest.
- Each directory under `examples/` is a `package main` program that imports the library with `import mylib "../.."`. Every example must build in CI.
- Platform-specific code goes in files with Odin's suffixes, for example `socket_linux.odin`, `socket_darwin.odin` and `socket_windows.odin`.
- Private helpers live in the same package and carry `@(private)` or `@(private = "file")`.

## Naming

| Kind | Style | Example |
| --- | --- | --- |
| Package | short, lowercase, one word where possible | `http`, `toml`, `uuid` |
| Repository | the package name, prefixed with `odin-` when the bare name is ambiguous | `odin-http` |
| Procedure | snake_case, verb first | `parse_header`, `buffer_destroy` |
| Variable and field | snake_case | `max_body_size` |
| Type | Ada_Case | `Request`, `Parse_Error` |
| Enum member | Ada_Case | `.Unexpected_Eof` |
| Constant | SCREAMING_SNAKE_CASE | `DEFAULT_PORT` |
| Test procedure | `test_` prefix, then what it proves | `test_parse_rejects_empty_key` |

Procedures that operate on a type start with the type's snake_case name: `buffer_init`, `buffer_write`, `buffer_destroy`. Don't repeat the package name in identifiers, because users already write `http.Request`, not `http.Http_Request`.

## Allocators and ownership

Odin has no garbage collector, so ownership must be obvious from the signature and the doc comment.

- Every procedure that allocates takes `allocator := context.allocator` as its last regular parameter, before `loc := #caller_location` if present.
- A struct that allocates stores the allocator it receives and uses it for every later allocation and free.
- Every type that owns memory has a matching `<type>_destroy` procedure. The caller frees a plain returned value, such as a string or slice, with `delete`, and the doc comment says so.
- The doc comment of every allocating procedure states who owns the result and how to free it.
- When a procedure only needs scratch memory, it uses `context.temp_allocator` internally and frees it before returning, or takes a `temp_allocator` parameter. It never leaves garbage in the caller's temporary allocator without saying so.
- Don't retain pointers into memory that the caller owns unless the doc comment says so. Copy instead.

```odin
/*
read_all reads the whole file at `path`.

Returns:
- data: the file contents, owned by the caller; free with `delete(data, allocator)`.
- err: an `os.Error` or an allocator error.
*/
read_all :: proc(path: string, allocator := context.allocator) -> (data: []byte, err: Error) {
	// ...
}
```

Tests run with Odin's tracking allocator, which `odin test` enables by default. A test that leaks memory fails review.

## Error handling

- Each failure domain gets an `enum` whose zero value is `None`, for example `Parse_Error :: enum { None, Unexpected_Eof, Invalid_Escape }`.
- When a procedure can fail in more than one domain, the package exposes a single `Error :: union #shared_nil { Parse_Error, io.Error, runtime.Allocator_Error }`. `nil` means success, and `#shared_nil` lets `or_return` flow between the variants.
- Fallible procedures return `(T, Error)`, with named results so that `or_return` works. Procedures that only fail return `Error` alone.
- When you need context such as a line and column, return a small struct next to the error, for example `(Document, Error, Location)`, rather than packing a string into the error.
- Library code never calls `panic`, `assert` on user input, `os.exit` or `log.fatal`. Use `assert` only for internal invariants that indicate a bug in the library itself.
- Errors print well: give enum members names that read as messages, because `fmt.println(err)` prints them.

## State and concurrency

- No global mutable state. Configuration lives in a struct that the user creates and passes in.
- Constants and read-only lookup tables at package scope are fine.
- Document thread safety on every type that users might share. The default answer is "a value is safe to use from one thread at a time".
- Don't start threads behind the user's back. If the library needs background work, the user calls a procedure that does it.

## Compiler flags

Every library compiles cleanly with:

```sh
odin check . -vet -strict-style -disallow-do -no-entry-point
odin test tests -vet -strict-style -disallow-do
```

- `-vet` catches unused variables and imports, shadowing and `using` statements.
- `-strict-style` enforces the compiler's own style: no stray semicolons, trailing commas in multi-line lists, attached braces, `case` aligned with `switch` and no deprecated syntax.
- `-disallow-do` bans the single-line `do` form; write a braced block instead.

CI runs both commands on Linux and macOS with the pinned compiler release in `.github/workflows/ci.yml`.

## Documentation

- Every exported declaration has a doc comment directly above it: procedures, types, constants, enum members whose meaning isn't obvious, and package-level variables.
- Start the comment with the declaration's name: `// parse_header reads one header line.`
- Use the layout from Odin's `core` library for longer comments: a summary, then `Inputs:`, `Returns:` and `Example:` sections inside a `/* */` block.
- The README follows `templates/README.md`. Every code sample in it must compile; copy them from `examples/` rather than writing them twice.

## Prose style

Vale checks every Markdown file in CI with the `OdinDocs` style plus `Vale` and `proselint`. The rules are short:

- Don't use words that talk down to the reader: `simply`, `just`, `easy`, `easily`, `obviously`.
- Use sentence case for headings below the title.
- Don't use exclamation marks.
- Spell out Latin abbreviations: write "for example" and "that is".
- Prefer active voice. Vale reports passive voice as a suggestion only.

Add project words, such as your package name, to `.github/styles/config/vocabularies/Odin/accept.txt`, one regular expression per line.

## Versioning

- Libraries follow [Semantic Versioning 2.0](https://semver.org/spec/v2.0.0.html). Tag releases as `v1.2.3`.
- Before `v1.0.0`, a minor bump may break the API. After it, only a major bump may.
- Changing the minimum supported Odin release is a minor bump. Note it in the changelog.
- Each release has a GitHub release whose notes are the matching changelog section.

## Changelog

`CHANGELOG.md` uses [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/). Every change that users can see adds a line under `## [Unreleased]` in one of the sections `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed` or `Security`. On release, rename the section to `## [1.2.3] - YYYY-MM-DD` and add a compare link at the bottom.

## Commits

Commits follow [Conventional Commits 1.0](https://www.conventionalcommits.org/en/v1.0.0/).

- Types: `feat`, `fix`, `docs`, `test`, `ci`, `chore`, `refactor`, `perf`.
- The subject is imperative, lowercase after the type, without a trailing period, and 72 characters or fewer.
- A blank line follows, then a body of `-` bullet points that say what changed and why.
- Mark breaking changes with `!` after the type and a `BREAKING CHANGE:` footer.
- Make several focused commits rather than one large one.

```text
feat: add streaming parser for large documents

- parse_stream reads from an io.Reader so files never sit fully in memory
- reuse the token buffer between calls to keep allocations flat
- document that the returned Document borrows nothing from the reader
```

Use the global Git identity. If none exists, set a repository-local one with the GitHub `noreply` address. Never commit a personal email address.

## Starting a new library

```sh
cp -R odin-standards/templates/. mylib/
cd mylib
git init -b main
# Rename mylib everywhere: files, package names, README, vocabulary.
vale sync
odin check . -vet -strict-style -disallow-do -no-entry-point
odin test tests -vet -strict-style -disallow-do
vale *.md
```
