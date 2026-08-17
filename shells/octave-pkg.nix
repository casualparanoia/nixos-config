{ pkgsUnstable }:

pkgsUnstable.mkShell {
  packages = [
    pkgsUnstable.octaveFull
    pkgsUnstable.gfortran
    pkgsUnstable.pkg-config
    pkgsUnstable.unzip
    pkgsUnstable.zip
  ];

  buildInputs = [
    pkgsUnstable.blas
    pkgsUnstable.lapack
  ];
}
