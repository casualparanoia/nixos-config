{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # Build systems, packaging, and debuggers
    pkgs.cmake
    pkgs.gnumake
    pkgs.ninja
    pkgs.pkg-config
    pkgs.gdb
    pkgs.lldb
    pkgs.valgrind
    pkgs.dpkg

    # Nix
    pkgsUnstable.nixd
    pkgs.nixfmt
    pkgs.statix
    pkgs.deadnix

    # Rust
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt
    pkgs.clippy
    pkgsUnstable.rust-analyzer

    # C / C++
    pkgs.clang-tools

    # C# / .NET 10 LTS
    pkgs.dotnet-sdk_10
    pkgsUnstable.csharp-ls
    pkgs.netcoredbg

    # Python
    pkgs.python3
    pkgsUnstable.uv
    pkgsUnstable.ruff
    pkgsUnstable.ty

    # Bash
    pkgsUnstable.bash-language-server
    pkgs.shellcheck
    pkgs.shfmt

    # Markdown
    pkgsUnstable.markdown-oxide
    pkgsUnstable.rumdl

    # YAML / KDL / TOML / JSON
    pkgs.yaml-language-server
    pkgs.yamllint
    pkgs.kdlfmt
    pkgsUnstable.tombi
    pkgs.vscode-langservers-extracted

    # Lua
    pkgsUnstable.lua-language-server
    pkgs.stylua

    # Fortran
    pkgs.gfortran
    pkgsUnstable.fortls
  ];
}
