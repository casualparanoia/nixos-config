{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # The device placeholder remains intentionally invalid in the tracked file.
        # Users should NOT replace it during installation.
        # `scripts/system install desktop` supplies the real device through Disko's `--disk main ...` override.
        device = "/dev/disk/by-id/PLEASE-SET-ME-DURING-INSTALL";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1024M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            # Note: No swap or hibernation storage is currently configured.
            # This is an explicit design choice to review before first installation.
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
