---
title: Metadata Schema
description: Frontmatter conventions for the system knowledge base.
tags:
  - documentation
  - metadata
  - schema
type: reference
status: accepted
date: 2026-08-14
---

# Metadata Schema

Keep frontmatter deliberately small. Add fields only when they support a real query, filter, index, or maintenance workflow.

## Core fields

```yaml
title: Human-readable page title
description: One-sentence purpose of the page
tags:
  - category
  - subsystem
type: page-kind
status: state
date: YYYY-MM-DD
```

Optional fields may include:

```yaml
aliases:
  - alternate name
source-files:
  - modules/example.nix
```

`source-files` is informational. Paths are written relative to the repository root.

## Recommended `type` values

| Type | Meaning |
|---|---|
| `architecture` | system/design description |
| `decision` | ADR-style choice with alternatives and consequences |
| `software` | one program/package/ecosystem |
| `hardware` | machine/device-specific behavior |
| `service` | service implementation and purpose |
| `runbook` | operational procedure |
| `concept` | reusable technical concept/policy |
| `investigation` | unresolved diagnostic work |
| `reference` | conventions or lookup material |
| `index` | navigation/dashboard page |

## Recommended `status` values

| Status | Meaning |
|---|---|
| `accepted` | deliberate current design choice |
| `active` | currently enabled/operational |
| `undecided` | alternatives remain open |
| `deferred` | intentionally postponed |
| `experimental` | enabled for evaluation |
| `planned` | accepted future work not yet implemented |
| `active-workaround` | temporary mitigation currently required |
| `investigating` | root cause or decision unresolved |
| `resolved` | no longer active, retained for history |
| `deprecated` | should no longer be used |

## Tags

Tags answer “what category is this?” rather than “what does this link to?”. Examples:

```text
#hardware
#science
#flatpak
#workaround
#amdgpu
#packaging
```

Use links such as `[[ngspice]]` for semantic relationships.
