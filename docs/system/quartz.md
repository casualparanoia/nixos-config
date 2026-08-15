---
title: Quartz Setup
description: Local Quartz 5 setup for rendering the repository documentation as a searchable wiki/knowledge graph.
tags:
  - documentation
  - quartz
  - setup
  - nixos
type: runbook
status: active
date: 2026-08-14
---

# Quartz Setup

Quartz is not the documentation database. It is a Node-based static-site generator and local development server that renders the Markdown under `docs/` as a searchable wiki.

## Intended topology

Keep Quartz outside the configuration repository:

```text
~/nixos-config/docs/   <- canonical content
~/quartz/              <- Quartz framework checkout
~/quartz/content       <- symlink to ~/nixos-config/docs
```

## Requirements

Quartz 5 currently requires Node.js 22 or later and npm. On NixOS, this does not need to become a permanent global package; a temporary Nix shell or a small dedicated devShell is sufficient.

## Setup outline

```bash
git clone https://github.com/jackyzha0/quartz.git ~/quartz
cd ~/quartz
npm i
npx quartz create
```

During `quartz create`:

- choose the **Obsidian** template because this knowledge base uses wikilinks and benefits from the graph/backlink-oriented configuration;
- choose the **symlink** content strategy;
- point the source at `~/nixos-config/docs`;
- if you are only using it locally, the deployment/base URL can be treated as a later publishing concern.

Then install the plugins referenced by the generated configuration:

```bash
npx quartz plugin install --from-config
```

Preview locally:

```bash
npx quartz build --serve
```

The development site is normally available on local port 8080 and watches content changes.

## Implementation

Quartz 5
Node requirement: >=22
Node currently supplied through temporary nix shell
Quartz checkout: ~/quartz
Quartz branch: system-knowledge-base
Content:
    ~/quartz/content -> ../nixos-config/docs

Local server:
    http://localhost:8080

Canonical documentation:
    ~/nixos-config/docs

Analytics:
    disabled

RSS / sitemap:
    disabled

Encrypted pages:
    disabled

Excalidraw:
    disabled

Known npm audit state:
    brace-expansion advisory
    esbuild Windows-only advisory
    sharp/libvips advisory
    no forced dependency upgrades applied

## Nix integration later

Do not add Quartz to the permanent system package list immediately. First validate that the workflow is useful. If it becomes permanent, create a small `devShell` (or a wrapper command) that supplies the required Node version reproducibly.

## Privacy

A local Quartz preview does not require publishing the knowledge base. If the repository or rendered site is ever made public, review the documentation for hardware identifiers, logs, addresses, tokens, or other machine/user-specific data first.

## Related

- [[Documentation System]]
- [[ADR 0001 - Documentation Architecture]]
