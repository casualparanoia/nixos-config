---
title: GNU Radio
description: GNU Radio and GNU Radio Companion for DSP/SDR work.
tags:
  - software
  - ee
  - dsp
  - sdr
  - communications
type: software
status: accepted
date: 2026-08-16
source-files:
  - home/engsci.nix
---

# GNU Radio

## Current configuration

```nix
pkgs.gnuradio
```

GNU Radio is installed from stable Nixpkgs as a persistent DSP/SDR application and framework.

Its internal Python dependency environment is an implementation detail of the packaged application and remains separate from the `uv`-based policy for user-created Python projects.

## Related

- [[Python Scientific Environments]]
- [[Scientific Software]]
