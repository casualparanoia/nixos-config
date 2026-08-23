{ ... }:

{
  users.users."casua" = {
    isNormalUser = true;
    description = "casua";
    # No actual SSH keys were added here.
    # Put shared authorized public keys here when needed.
    openssh.authorizedKeys.keys = [ ];
  };
}
