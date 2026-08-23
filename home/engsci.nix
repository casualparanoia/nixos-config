# ~/nixos-config/home/science.nix
{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # ----- Numerical / scientific computing -----

    # Current Octave; keep Forge packages out of the global HM generation.
    pkgsUnstable.octaveFull

    # Official Julia binary repackaged by Nixpkgs.
    pkgsUnstable.julia-bin

    # Computer algebra / mathematics.
    # Sage's test suite is a separate, very expensive derivation and is not
    # required at runtime. Avoid forcing it into normal system builds.
    (pkgsUnstable.sage.override {
      requireSageTests = false;
    })

    # R 4.6.1 in unstable.
    pkgsUnstable.R


    # ----- Circuit / RF / EDA -----

    # SPICE simulator.
    # Keep the Nixpkgs version for now; consider our own ngspice 47 later.
    # pkgsUnstable.ngspice

    # Schematic frontend + multiple simulation kernels.
    # pkgsUnstable.qucs-s

    # High-performance SPICE-compatible simulator.
    pkgsUnstable.xyce

    # PCB / schematic EDA suite.
    pkgsUnstable.kicad

    # EM field solver.
    # Use unstable to keep its Octave dependency in the same package set
    # as our unstable Octave installation.
    pkgsUnstable.openems

    # SDR / DSP framework and GNU Radio Companion.
    pkgsUnstable.gnuradio

    # Optional: expose qucsator_rf directly on the normal shell PATH.
    # Qucs-S already contains it as one of its default simulation kernels.
    # pkgsUnstable.qucsator-rf


    # ----- Optional scientific frontend -----

    # pkgsUnstable.kdePackages.cantor
  ];
}
