# Making Odin a great replacement for Go, TypeScript and Swift

Odin already wins on the things a language decides alone: fast compiles, explicit memory, a readable syntax, real arrays of structs and a `core` library written with taste. It loses on the things an ecosystem decides: how fast a developer gets from an empty folder to a running service, a CLI tool or an app on a phone.

This document says where the gap is and in what order the `alexisbcz` libraries close it. It's opinionated. Each priority answers one question: what stops a team that writes Go, TypeScript or Swift today from writing its next project in Odin?

## What developers get elsewhere

| Area | Go | TypeScript | Swift | Odin today |
| --- | --- | --- | --- | --- |
| Standard library breadth | Huge: HTTP, TLS, SQL interfaces, templates, crypto | Small, but the platform (browser, Node, Deno, Bun) fills it | Foundation plus Apple frameworks | Solid `core`: JSON, CBOR, XML, CSV, regex, crypto, sockets, threads, time zones. No HTTP, no TLS, no SQL |
| Package management | `go get`, module proxy, checksum database | npm, pnpm, JSR | Swift Package Manager | None official. Git submodules and copied folders |
| HTTP and networking | `net/http` in the standard library | `fetch` everywhere, many frameworks | `URLSession`, SwiftNIO | Raw sockets in `core:net`; HTTP only through community projects |
| Async and concurrency | Goroutines and channels | `async`/`await` on an event loop | `async`/`await`, actors | Threads, `core:sync` and a young non-blocking IO layer. No shared async story |
| Tooling | `go` command does build, test, format, vet, docs | `tsc`, ESLint, Prettier, Vite | Xcode, SourceKit-LSP | `odin` compiler with `check`, `test`, `doc`; OLS for editors; `odinfmt` |
| Testing | `go test`, benchmarks, fuzzing, coverage | Vitest, Jest, Playwright | XCTest, Swift Testing | `odin test` with leak tracking. No fuzzing, coverage or snapshot helpers |
| Formatting | `gofmt`, universal | Prettier, near universal | `swift-format` | `odinfmt` exists but many projects don't run it |
| Mobile and GUI | Weak | React Native, Electron, the web itself | SwiftUI, UIKit, first-class | Excellent game and immediate-mode bindings in `vendor`. No native widgets, no mobile app story |
| Documentation | pkg.go.dev for every module | TypeDoc, JSR docs | DocC | `odin doc` output; no hosted index for third-party code |

## Where Odin is already better

- **Memory is explicit and cheap.** Allocators in `context` give every library arena, pool and tracking allocators at no extra cost. Go and TypeScript can't offer this; Swift hides it behind reference counting.
- **Build times and deployment.** One compiler, one static binary, no runtime to install.
- **Data-oriented design.** `#soa` arrays, bit sets, fixed arrays and enumerated arrays make fast code the default.
- **C interop.** `foreign import` makes binding a C library an afternoon of work. That's the shortcut to most of the gaps below.

## What's missing, in order

The order follows one rule: unblock the most common program first. Most new software is a networked service or a command-line tool that talks to one, so networking and data come before GUI.

### Priority 1: the networked service

1. **TLS.** A thin, safe binding over a system library: Secure Transport or Network on macOS, OpenSSL or a bundled BoringSSL on Linux, SChannel on Windows. Without TLS no HTTP client is useful.
2. **HTTP/1.1 client.** Synchronous first, with timeouts, redirects, connection reuse and streaming bodies. The Odin answer to `fetch` and `http.Get`.
3. **HTTP/1.1 server.** A router, middleware as plain procedures, request-scoped arenas, graceful shutdown. Build it on the shared IO layer below so it scales without a thread per connection.
4. **IO event loop.** One shared abstraction over kqueue, epoll and IOCP, so that the HTTP, database and WebSocket libraries all run on the same loop instead of three incompatible ones.
5. **Structured logging.** A `core:log` compatible logger that writes JSON or logfmt with fields, levels and request IDs.

### Priority 2: data and storage

1. **SQLite.** Bundled amalgamation, prepared statements, typed row scanning into structs.
2. **PostgreSQL client.** Native wire protocol, no `libpq`, prepared statements, connection pool.
3. **Struct mapping.** Reflection-based encode and decode shared by JSON, TOML, SQL rows and URL query strings, with field tags that work the same everywhere.
4. **TOML and YAML.** Configuration files are the first thing a service reads. TOML first; a YAML subset second.
5. **Migrations.** A small, file-based migration runner for SQLite and PostgreSQL.

### Priority 3: the developer loop

1. **Package tool.** Not a registry. A command that reads a manifest, fetches Git dependencies at pinned commits into a `libs/` folder, writes a lock file and prints the `-collection` flags. This removes the worst friction of submodules without inventing infrastructure.
2. **Test helpers.** Table-driven test utilities, golden files, property-based testing and a fuzzing harness over `odin test`.
3. **Benchmarks.** A small harness that runs a procedure until the timing settles and prints allocations per operation, like `go test -bench`.
4. **Doc site generator.** Turn `odin doc -doc-format` output into a static site per library, published from CI.
5. **Formatting in CI.** A pinned `odinfmt` check in the shared workflow once its output is stable across releases.

### Priority 4: tools for the terminal

1. **Terminal UI.** Colors, terminal size, raw mode, progress bars and a small widget layer for interactive prompts.
2. **Subcommands.** `core:flags` parses flags well. Add a thin layer for `tool verb --flag` command trees with generated help.
3. **File watching.** One API over FSEvents, inotify and ReadDirectoryChangesW, for dev servers and build tools.

### Priority 5: the wider web

1. **WebSocket client and server** on the shared event loop.
2. **HTTP/2** for the client, which modern APIs increasingly require.
3. **Templates.** A compiled, type-checked HTML template package for server-rendered pages.
4. **WebAssembly helpers** for the `js_wasm32` target: DOM bindings and a `fetch` wrapper, so that one language can cover both the server and the browser.

### Priority 6: desktop and mobile

1. **Native windowing and menus** through thin bindings to AppKit, Win32 and GTK, for small utilities that must look native.
2. **Swift and Kotlin bridges.** Ship Odin as a static library inside an Xcode or Gradle project, with generated headers. Odin won't replace SwiftUI soon; it can own the core logic underneath it.
3. **Immediate-mode app kit.** Package what already works (raylib, SDL, microui) into a starter that handles text input, high-DPI screens and accessibility basics.

## What not to build

- **A central registry.** Git URLs and tags already work. A registry needs moderation and uptime that a small ecosystem can't staff.
- **A garbage-collected runtime or a coroutine scheduler hidden in the language.** The event loop is a library, and memory stays explicit.
- **Framework lock-in.** Every library takes plain values and allocators, so users can mix them with code from anyone else.

## How to measure progress

The roadmap succeeds when each of these takes under an hour for someone new to Odin:

- Write a JSON API backed by PostgreSQL, served over HTTPS, with tests and structured logs.
- Write a CLI tool that calls that API, with subcommands, colors and a single static binary for three platforms.
- Add any `alexisbcz` library to a project with one command and a lock file.
