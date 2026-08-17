{ pkgsUnstable }:

pkgsUnstable.mkShell {
  packages = [
    pkgsUnstable.octaveFull

    # Build tools
    pkgsUnstable.gfortran
    pkgsUnstable.pkg-config

    # Archive helpers
    pkgsUnstable.unzip
    pkgsUnstable.zip
  ];

  buildInputs = [
    # Core numerical libraries
    pkgsUnstable.blas
    pkgsUnstable.lapack

    # communications
    pkgsUnstable.hdf5

    # general
    pkgsUnstable.nettle

    # sqlite
    pkgsUnstable.sqlite

    # strings
    pkgsUnstable.pcre2

    # audio
    pkgsUnstable.rtmidi
    pkgsUnstable.alsa-lib
    pkgsUnstable.jack2

    # ltfat
    pkgsUnstable.fftw
    pkgsUnstable.fftwSinglePrec
    pkgsUnstable.fftwFloat
    pkgsUnstable.fftwLongDouble
    pkgsUnstable.portaudio
    pkgsUnstable.jdk
  ];
}
