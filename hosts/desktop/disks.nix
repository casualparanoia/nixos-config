{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # DO NOT hardcode /dev/nvme0n1 or similar, as enumeration can change.
        # When booted from the live ISO, identify the correct disk (e.g. by using `lsblk` and checking model/size)
        # Then replace this placeholder with the stable `/dev/disk/by-id/...` path.
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
