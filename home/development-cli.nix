{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # Build systems, packaging, and debuggers
    pkgsUnstable.cmake
    pkgsUnstable.gnumake
    pkgsUnstable.ninja
    pkgsUnstable.pkg-config
    pkgsUnstable.gdb
    pkgsUnstable.lldb
    pkgsUnstable.valgrind
    pkgsUnstable.dpkg

    # Nix
    pkgsUnstable.nixd
    pkgsUnstable.nixfmt
    pkgsUnstable.statix
    pkgsUnstable.deadnix

    # Rust
    pkgsUnstable.cargo
    pkgsUnstable.rustc
    pkgsUnstable.rustfmt
    pkgsUnstable.clippy
    pkgsUnstable.rust-analyzer

    # C / C++
    pkgsUnstable.clang-tools

    # C# / .NET 10 LTS
    pkgsUnstable.dotnet-sdk_10
    pkgsUnstable.csharp-ls
    pkgsUnstable.netcoredbg

    # Python
    pkgsUnstable.python3
    pkgsUnstable.uv
    pkgsUnstable.ruff
    pkgsUnstable.ty

    # Bash
    pkgsUnstable.bash-language-server
    pkgsUnstable.shellcheck
    pkgsUnstable.shfmt

    # Markdown
    pkgsUnstable.markdown-oxide
    pkgsUnstable.rumdl

    # YAML / KDL / TOML / JSON
    pkgsUnstable.yaml-language-server
    pkgsUnstable.yamllint
    pkgsUnstable.kdlfmt
    pkgsUnstable.tombi
    pkgsUnstable.vscode-langservers-extracted

    # Lua
    pkgsUnstable.lua-language-server
    pkgsUnstable.stylua

    # Fortran
    pkgsUnstable.gfortran
    pkgsUnstable.fortls

    # Version Control
    pkgsUnstable.gh
    pkgsUnstable.git
    pkgsUnstable.delta
    pkgsUnstable.lazygit
    pkgsUnstable.jujutsu
    pkgsUnstable.lazyjj
  ];
}
