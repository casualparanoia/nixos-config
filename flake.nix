# ~/nixos-config/flake.nix
{
  description = "casua's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nirinit = {
      url = "github:amaanq/nirinit/9ae6f110c652aab8b2ce28dd3696829e8fa1b628"; # v0.2.2
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/440818969ac2cbd77bfe025e884d0aa528991374"; # v0.7.0
    vicinae.url = "github:vicinaehq/vicinae";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      helium,
      antigravity-nix,
      nirinit,
      nix-flatpak,
      vicinae,
      nix-index-database,
      ...
    }:
    let
      system = "x86_64-linux";

      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit pkgsUnstable;
        };

        modules = [
          ./configuration.nix

          nirinit.nixosModules.nirinit
          nix-flatpak.nixosModules.nix-flatpak
          nix-index-database.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;

              backupFileExtension = "hm-backup";

              sharedModules = [
                vicinae.homeManagerModules.default
              ];

              extraSpecialArgs = {
                inherit pkgsUnstable helium antigravity-nix;
              };

              users.casua = import ./home/home.nix;
            };
          }
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

      devShells.${system}.octave-pkg = import ./shells/octave-pkg.nix {
        inherit pkgsUnstable;
      };

    };
}
