{ pkgs, pkgsUnstable, ... }:

{
  home.packages = with pkgsUnstable; [
    (heroic.override {
      extraPkgs = pkgs': [ pkgs'.gamemode ];
    })
    (lutris.override {
      steamSupport = false;
      extraPkgs = pkgs': [ pkgs'.gamemode ];
    })
    umu-launcher
  ];

  programs.mangohud = {
    enable = true;
    package = pkgsUnstable.mangohud;
    enableSessionWide = false;

    settings = {
      position = "top-right";
      fps = true;
      frametime = true;
      frame_timing = true;
      cpu_stats = true;
      cpu_temp = true;
      gpu_stats = true;
      gpu_temp = true;
      vram = true;
      ram = true;
      gamemode = true;
      vulkan_driver = true;
      wine = true;
      arch = true;
    };
  };
}
