{ pkgs, pkgsUnstable, ... }:

{
  programs.helix = {
    enable = true;
    package = pkgsUnstable.helix;

    settings = {
      theme = "ayu_dark";

      editor = {
        line-number = "relative";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        lsp.display-messages = true;
      };

      keys.normal = {
        space.space = "file_picker";
        space.W = ":w";
        space.q = ":q";
      };
    };

    languages = {
      language-server = {
        csharp-ls = {
          command = "${pkgsUnstable.csharp-ls}/bin/csharp-ls";
          config.csharp.analyzersEnabled = true;
        };

        bash-language-server = {
          command = "${pkgsUnstable.bash-language-server}/bin/bash-language-server";
          args = [ "start" ];

          config.bashIde = {
            shellcheckPath = "${pkgs.shellcheck}/bin/shellcheck";
            shfmt.path = "${pkgs.shfmt}/bin/shfmt";
          };
        };

        rumdl = {
          command = "${pkgsUnstable.rumdl}/bin/rumdl";
          args = [ "server" ];
        };
      };

      language = [
        {
          name = "nix";
          language-servers = [ "nixd" ];
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }

        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
        }

        {
          name = "c";
          language-servers = [ "clangd" ];
          formatter.command = "${pkgs.clang-tools}/bin/clang-format";
        }

        {
          name = "cpp";
          language-servers = [ "clangd" ];
          formatter.command = "${pkgs.clang-tools}/bin/clang-format";
        }

        {
          name = "c-sharp";
          language-servers = [ "csharp-ls" ];
        }

        {
          name = "python";
          language-servers = [
            "ty"
            {
              name = "ruff";
              only-features = [
                "diagnostics"
                "code-action"
                "format"
              ];
            }
          ];
        }

        {
          name = "bash";
          language-servers = [ "bash-language-server" ];
        }

        {
          name = "markdown";
          language-servers = [
            "markdown-oxide"
            {
              name = "rumdl";
              only-features = [
                "diagnostics"
                "code-action"
                "format"
              ];
            }
          ];
        }

        {
          name = "yaml";
          language-servers = [ "yaml-language-server" ];
        }

        {
          name = "kdl";
          language-servers = [ ];
          formatter = {
            command = "${pkgs.kdlfmt}/bin/kdlfmt";
            args = [
              "format"
              "-"
            ];
          };
        }

        {
          name = "toml";
          language-servers = [ "tombi" ];
        }

        {
          name = "json";
          language-servers = [ "vscode-json-language-server" ];
        }

        {
          name = "lua";
          language-servers = [ "lua-language-server" ];
          formatter = {
            command = "${pkgs.stylua}/bin/stylua";
            args = [ "-" ];
          };
        }

        {
          name = "fortran";
          language-servers = [ "fortls" ];
        }

        {
          name = "nu";
          language-servers = [ "nu-lsp" ];
        }

        {
          name = "fish";
          language-servers = [ ];
          formatter.command = "${pkgs.fish}/bin/fish_indent";
        }
      ];
    };
  };
}
