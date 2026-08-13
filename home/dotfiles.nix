# ~/nixos-config/home/dotfiles.nix
{lib, ... }:
{
  options.my.dotfiles.mode = lib.mkOption {
    type = lib.types.enum [
	"live"
	"store"
    ];

    default = "live";

    description = ''
	How application dotfiles are managed.

	"live":
	  Link directly to ~/nixos-config/dotfiles so edits take effect without a Home manager activation.

	"store":
	  Let Nix snapshot the files into the immutable store so their contects belong to the Home Manager generation.
    '';
  };
}
