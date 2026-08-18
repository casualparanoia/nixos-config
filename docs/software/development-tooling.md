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
date: 2026-08-16
source-files:
  - home/development.nix
  - home/wezterm.nix
  - home/helix.nix
  - home/yazi.nix
---

# Development Tooling

`home/development.nix` provides a reusable workstation baseline. Project libraries and project-specific toolchain versions still belong in a Nix `devShell` or a language-native locked environment.

## Tooling policy

Many fast-moving development tools (such as `rust-analyzer`, `nixd`, `csharp-ls`, `uv`, `ruff`, and most language servers) are explicitly pulled from the unstable package set to ensure they support the latest language features and editor integrations.

## Installed baseline

| Area | Tools |
|---|---|
| Build, debug, and packaging | GCC, `clang-tools`, CMake, Make, Ninja, `pkg-config`, GDB, LLDB, Valgrind, `dpkg` |
| Version control | Git, GitHub CLI (`gh`) |
| Nix | `nixd`, `nixfmt`, Statix, deadnix |
| Rust | Cargo, Rust compiler, rustfmt, Clippy, rust-analyzer |
| C# / .NET | .NET 10 LTS SDK, `csharp-ls`, `netcoredbg` |
| Python | Python 3, `uv`, Ruff, `ty` |
| Shell | `bash-language-server`, ShellCheck, `shfmt` |
| Markdown | `markdown-oxide`, `rumdl` |
| YAML | `yaml-language-server`, yamllint |
| KDL | `kdlfmt` |
| TOML | Tombi |
| JSON | VS Code JSON language server; `jq` remains in the general package module |
| Lua | `lua-language-server`, `stylua` |
| Fortran | `gfortran`, `fortls` |

`clang-tools` supplies both `clangd` and `clang-format`. `vscode-langservers-extracted` supplies `vscode-json-language-server`.

The `gfortran` package remains explicitly installed. The separate `gcc` package declaration was removed because GCC remains available in the resulting development environment.

Prettier is no longer part of the configured development-tooling baseline.

`dpkg-deb` supports Debian-package inspection in `scripts/nix-binary-inspect`; it is tooling for local package maintenance, not a second system package manager.

## Terminal and editor environments

The primary terminal emulator (WezTerm), editor (Helix), and file manager (Yazi) are managed by Home Manager modules (`home/wezterm.nix`, `home/helix.nix`, `home/yazi.nix`). Their native configuration files reside in the `dotfiles/` directory.

Home Manager is configured to link these native dotfiles directly. When in "live" mode, they are linked out-of-store, allowing real-time configuration changes without requiring a system rebuild.

### Editor integrations (Helix)

Helix is explicitly configured in `home/helix.nix` to integrate the baseline tooling:

- **Python**: Helix uses both `ty` and `ruff`, with a strict responsibility split where `ruff` is restricted via `only-features` to diagnostics, code actions, and formatting.
- **C#**: `csharp-ls` is configured to enable Roslyn analyzers.
- **Bash**: `bash-language-server` is configured to use the standalone `shellcheck` and `shfmt` binaries for integrated linting and formatting.
- **Markdown**: `markdown-oxide` provides general language features, while `rumdl` is restricted to diagnostics, code actions, and formatting.
- **Formatting**: Helix explicitly maps external formatters for languages without integrated language-server formatting (e.g., `nixfmt` for Nix, `clang-format` for C/C++, `stylua` for Lua, `kdlfmt` for KDL, and `fish_indent` for Fish).

## Python baseline

Nix supplies the Python interpreter, `uv`, Ruff, and `ty`. Project dependencies stay in `uv` environments, with Nix `devShell`s reserved for native/system dependencies and stronger Nix-level reproducibility. See [[Python Scientific Environments]].

## Repository formatting

The flake exposes `nixfmt` as its formatter, so all Nix files can be formatted from the repository root with:

```bash
nix fmt
```

## Related

- [[Project Environments]]
- [[Package Source Policy]]
- [[Antigravity]]
