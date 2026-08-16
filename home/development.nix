{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Build and debugging foundations
    gcc
    clang-tools
    cmake
    gnumake
    ninja
    pkg-config
    gdb
    lldb
    valgrind
    dpkg

    # Nix
    nixd
    nixfmt
    statix
    deadnix

    # Rust
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # C# / .NET 10 LTS
    dotnet-sdk_10
    csharp-ls
    netcoredbg

    # Python
    python3
    uv
    ruff
    ty

    # Shell
    bash-language-server
    shellcheck
    shfmt

    # Markdown, YAML, KDL, TOML, and JSON
    marksman
    markdownlint-cli2
    yaml-language-server
    yamllint
    kdlfmt
    taplo
    vscode-langservers-extracted
    prettier
  ];
}
