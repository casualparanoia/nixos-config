# ~/nixos-config/home/science.nix
{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # ----- Numerical / scientific computing -----

    # Current Octave; keep Forge packages out of the global HM generation.
    pkgsUnstable.octaveFull

    # Official Julia binary repackaged by Nixpkgs.
    pkgs.julia-bin

    # Computer algebra / mathematics.
    pkgs.sage

    # R 4.6.1 in unstable.
    pkgsUnstable.R


    # ----- Circuit / RF / EDA -----

    # SPICE simulator.
    # Keep the Nixpkgs version for now; consider our own ngspice 47 later.
    # pkgs.ngspice

    # Schematic frontend + multiple simulation kernels.
    # pkgs.qucs-s

    # High-performance SPICE-compatible simulator.
    pkgs.xyce

    # PCB / schematic EDA suite.
    pkgs.kicad

    # EM field solver.
    # Use unstable to keep its Octave dependency in the same package set
    # as our unstable Octave installation.
    pkgsUnstable.openems

    # SDR / DSP framework and GNU Radio Companion.
    pkgs.gnuradio

    # Optional: expose qucsator_rf directly on the normal shell PATH.
    # Qucs-S already contains it as one of its default simulation kernels.
    # pkgs.qucsator-rf


    # ----- Optional scientific frontend -----

    # pkgs.kdePackages.cantor
  ];
}
