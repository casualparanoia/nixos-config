---
title: ADR 0001 - Documentation Architecture
description: Decision to keep Markdown documentation in the NixOS repository and use Quartz as a replaceable knowledge-base frontend.
tags:
  - adr
  - documentation
  - quartz
  - docs-as-code
type: decision
status: accepted
date: 2026-08-14
aliases:
  - Documentation Architecture Decision
---

# ADR 0001 - Documentation Architecture

## Context

The Nix source increasingly contains hardware workarounds, diagnostic services, custom packages, package-source decisions, and temporary experiments. Source code alone records implementation but does not reliably preserve motivation, alternatives, caveats, operational procedures, or removal criteria.

A directory of unrelated Markdown files would preserve text but would not fully solve discoverability. Search, backlinks, tags, navigation, and cross-linking are needed.

## Decision

1. Keep canonical documentation as Markdown under `docs/` in the same Git repository as the NixOS configuration.
2. Use frontmatter, tags, explicit wiki links, indexes, tables, and task lists to structure the knowledge base.
3. Use Quartz 5 as a replaceable local wiki/search/graph renderer over `docs/`.
4. Keep the Quartz framework itself outside this repository and symlink its `content/` directory to `nixos-config/docs/`.
5. Permit any editor (Kate, Helix, optionally Obsidian) to edit the same Markdown files.
6. Record undecided choices explicitly rather than pretending every investigated option is settled.

## Consequences

### Positive

- documentation and implementation can change in one Git commit;
- no proprietary or opaque data store is required;
- raw files remain readable without Quartz;
- full-text search, backlinks, tags, and graph views become available;
- workarounds can carry explicit removal criteria;
- unresolved package decisions remain searchable institutional memory.

### Negative

- Markdown metadata and links require some discipline;
- Quartz adds a separate Node-based tool to run when the rendered wiki is desired;
- indexes can become stale if they are manually maintained.

## Revisit when

Reconsider the frontend if Quartz becomes difficult to maintain or another renderer can consume the same Markdown more effectively. The Markdown storage model should remain independent of that choice.

## Related

- [[Documentation System]]
- [[Metadata Schema]]
