---
title: Development Tooling
description: Persistent compilers, SDKs, debuggers, language servers, formatters, and linters managed by Home Manager.
tags:
  - software
  - development
  - lsp
  - formatting
type: software
status: active
date: 2026-08-15
source-files:
  - home/development.nix
---

# Development Tooling

`home/development.nix` provides a reusable workstation baseline. Project libraries and project-specific toolchain versions still belong in a Nix `devShell` or a language-native locked environment.

## Installed baseline

| Area | Tools |
|---|---|
| Build and debug | GCC, `clang-tools`, CMake, Make, Ninja, `pkg-config`, GDB, LLDB, Valgrind |
| Nix | `nixd`, `nixfmt`, Statix, deadnix |
| Rust | Cargo, Rust compiler, rustfmt, Clippy, rust-analyzer |
| C# / .NET | .NET 10 LTS SDK, `csharp-ls`, `netcoredbg` |
| Shell | `bash-language-server`, ShellCheck, `shfmt` |
| Markdown | Marksman, `markdownlint-cli2`, Prettier |
| YAML | `yaml-language-server`, yamllint, Prettier |
| KDL | `kdlfmt` |
| TOML | Taplo |
| JSON | VS Code JSON language server, Prettier; `jq` remains in the general package module |

`clang-tools` supplies both `clangd` and `clang-format`. `vscode-langservers-extracted` supplies `vscode-json-language-server`.

## Python boundary

No Python runtime, package manager, language server, formatter, or global Python package set is added here. The choice between `uv`, Nix `devShell`s, or a hybrid remains deferred in [[Python Scientific Environments]].

## Repository formatting

The flake exposes `nixfmt` as its formatter, so all Nix files can be formatted from the repository root with:

```bash
nix fmt
```

## Related

- [[Project Environments]]
- [[Package Source Policy]]
- [[Antigravity]]
