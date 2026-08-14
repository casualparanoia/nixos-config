---
title: Documentation System
description: Architecture and operating rules for the NixOS configuration knowledge base.
tags:
  - documentation
  - architecture
  - quartz
  - docs-as-code
type: architecture
status: accepted
date: 2026-08-14
source-files:
  - docs/
---

# Documentation System

The configuration uses a **docs-as-code** knowledge base. Markdown in `docs/` is canonical and committed in the same Git history as the Nix code it explains.

See [[ADR 0001 - Documentation Architecture]].

## Design goals

The documentation must support:

- full-text search;
- navigation by folder and index pages;
- tags;
- backlinks and explicit relationships;
- a graph view when useful;
- tables and task lists;
- durable Git history;
- readable files without a special application;
- recording undecided questions as well as accepted decisions.

## Source of truth

```text
nixos-config/
├── *.nix, modules/, home/, packages/, scripts/
└── docs/                    <- canonical documentation
```

Quartz is a renderer/indexer, not the database. Obsidian may later be used as an editor, but it must not become the only place where information exists.

## Quartz integration

Quartz 5 expects its content under its own `content/` directory. The intended deployment is to keep Quartz as a separate checkout and initialize it with a **symlink content strategy** pointing to this repository's `docs/` directory.

Conceptually:

```text
~/nixos-config/docs/             canonical Markdown
          ^
          |
          | symlink
          |
~/quartz/content/                Quartz content path
          |
          +--> search / graph / backlinks / rendered wiki
```

This avoids adding the Quartz framework and Node dependency tree to the NixOS configuration repository.

## Editing

Any Markdown-capable editor is valid. Kate and Helix are sufficient. Obsidian is optional and can open `docs/` directly as a vault if its graph/editor workflow becomes useful.

## Linking

Use wiki links for conceptual relationships between documentation pages. Use ordinary Markdown links for external resources.

Prefer explicit links in prose over adding a generic `related:` field to every page. The link graph should represent meaningful relationships, not metadata noise.

## Page status

Status records the state of the subject, not whether a page is complete. See [[Metadata Schema]].

Examples:

- `accepted`: deliberate current design choice;
- `active`: currently operational component;
- `undecided`: alternatives are still being evaluated;
- `deferred`: explicitly postponed;
- `active-workaround`: temporary workaround currently required;
- `investigating`: unresolved problem under diagnosis;
- `resolved`: historical problem that no longer requires action.

## Documentation rule

When a non-obvious configuration choice changes, update the relevant documentation in the **same Git commit** whenever practical.

A source comment should explain the immediate mechanism and point to the knowledge-base page; the Markdown page should carry the history, alternatives, caveats, and removal criteria.
