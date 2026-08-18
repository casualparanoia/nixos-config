---
title: Documentation Style
description: Authoring conventions for technical prose, evidence, procedures, commands, and page structure in the NixOS knowledge base.
type: reference
status: active
tags:
  - system
  - documentation
  - style
  - docs-as-code
---

# Documentation Style

## Purpose

This page defines how individual documents in the NixOS knowledge base should
be written.

It complements:

- `documentation-system.md`, which defines the structure and operating rules of
  the documentation system;
- `metadata-schema.md`, which defines machine-readable frontmatter and taxonomy;
- decision records, which preserve why significant documentation choices were
  made.

The goal is not stylistic uniformity for its own sake. The goal is to make
documentation easier to retrieve, verify, maintain, and trust after the original
context has disappeared.

## Core principles

### Optimize for retrieval

Pages should be easy to scan, search, and revisit.

Prefer:

- descriptive titles and headings;
- short, focused sections;
- direct statements;
- complete commands that can be copied;
- explicit file, host, service, module, package, and option names;
- examples close to the explanation they demonstrate;
- links to related canonical pages.

Avoid:

- long introductions;
- vague headings such as `Notes`, `Details`, or `Miscellaneous`;
- unexplained abbreviations;
- repeating the same explanation on several pages;
- documenting obvious code without explaining why it exists.

A page should normally begin with a short summary that answers:

1. what the subject is;
2. why it exists or matters;
3. its present operational state, when relevant.

### Explain why, not every line

Nix files are the source of truth for declarative configuration.

Documentation should explain:

- why a setting exists;
- what problem it solves;
- what assumptions it makes;
- what it does not configure;
- how to use or verify it;
- how to remove, replace, or revisit it;
- what limitations or workarounds exist.

Do not manually duplicate complete package, option, or configuration inventories
when the information can already be read directly from the source.

A source comment should explain a local mechanism or surprising implementation
detail.

A documentation page should contain the wider context, rationale, history,
trade-offs, operational procedure, limitations, and verification information.

### Preserve reasoning

Important choices should remain understandable after the original context has
disappeared.

Record, when relevant:

- constraints;
- alternatives considered;
- trade-offs;
- rejected approaches;
- consequences;
- assumptions;
- conditions under which the choice should be revisited.

Use a decision record when the reasoning is more important than the current
configuration itself.

### Prefer explicitness over cleverness

Documentation may be personal and informal, but it should not require guesswork.

State explicitly:

- which host or environment a procedure applies to;
- whether a command changes persistent state;
- whether a setting is temporary;
- what assumptions are being made;
- what success looks like;
- what to do when the expected result does not occur.

### One fact, one canonical explanation

A fact, mechanism, procedure, or decision should have one page that owns its full
explanation.

Other pages should summarize only what is needed for their own context and link
to the canonical page.

Avoid maintaining parallel copies of:

- package inventories;
- installation procedures;
- architecture explanations;
- known limitations;
- decision rationale;
- recovery procedures.

Duplication is acceptable only when the repeated text is small, local, and
necessary to make a procedure understandable without excessive navigation.

## Voice

Use a neutral, direct, and technically precise style.

Descriptive material should normally use the system, host, module, service,
application, component, or process as the grammatical subject.

Prefer:

> The service archives the previous boot before starting the monitor.

Avoid:

> We archive the previous boot before starting the monitor.

Procedures should use direct imperative instructions.

Prefer:

> Restart the service.

Avoid:

> You should restart the service.

and:

> The service should now be restarted.

First-person language may be used in quoted material, historical context, or
investigation notes when authorship itself matters.

Avoid unnecessary conversational filler and subjective qualifiers such as:

- obviously;
- clearly;
- simply;
- just;
- easy;
- trivial.

If something is uncertain, state the basis and scope of the uncertainty rather
than hiding it behind vague wording.

## Evidence and certainty

Engineering documentation must distinguish what was observed from what was
inferred.

### Observation

An observation is directly supported by configuration, command output, a log,
measurement, reproduced behavior, or other captured evidence.

Example:

> The resume attempt produced AMDGPU SMU timeout messages and the display did
> not recover.

### Inference

An inference is a conclusion derived from one or more observations.

Example:

> The GPU power-management path was in a failed state after the resume attempt.

### Hypothesis

A hypothesis is a possible explanation that has not been established.

Example:

> A Polaris power-management failure may be involved in the suspend problem.

A hypothesis should normally state the evidence that supports it and the
evidence that weakens it.

### Assumption

An assumption is a condition accepted for the purpose of a procedure, test, or
analysis.

Example:

> This test assumes the crash monitor survives long enough to archive the
> previous boot on the next startup.

### Decision

A decision is a deliberate choice.

A decision does not become an empirical fact merely because it has been
implemented.

### Avoid overstating evidence

Prefer:

> No NVMe error was logged during this test.

Avoid:

> NVMe was not involved.

Prefer:

> Disabling APST did not prevent the crashes, which weakens APST as the primary
> explanation.

Avoid:

> APST has been ruled out.

Absence of evidence should not be presented as evidence of absence unless the
test was specifically capable of establishing that conclusion.

### Investigation state vocabulary

When tracking hypotheses, prefer a small, consistent vocabulary:

- `unexplored`
- `plausible`
- `supported`
- `weakened`
- `rejected`
- `established`

Use `rejected` conservatively. A test usually rejects a specific mechanism under
specific conditions, not an entire subsystem.

## Temporal language

Avoid time-relative language that will become ambiguous or stale.

Prefer:

> Tombi is the selected TOML language server.

Avoid:

> Tombi is currently the newest TOML language server we use.

When time or version is part of the technical explanation, state it explicitly:

> As tested on 2026-08-18 with Tombi 0.11.x, schema-aware linting worked in
> Helix.

Avoid vague temporal terms such as:

- currently;
- new;
- old;
- recently;
- lately;
- for now;
- the latest;

unless the relative timing is itself the subject of the statement.

Do not duplicate version information that is already reliably represented by
`flake.lock` or Nix source unless the version materially affects the explanation.

Useful reasons to record a version include:

- a bug exists only before or after a release;
- a migration depends on a version boundary;
- evidence was captured on a particular kernel or package version;
- a package-source decision exists because one package set materially lags
  another.

Git history is the source of truth for file modification history. Do not add
manual per-page changelogs unless historical changes are necessary to explain
the present system.

## Requirements language

Use requirement words consistently:

- `must` — a required invariant or necessary condition;
- `should` — the recommended default, with justified exceptions possible;
- `may` — permitted or optional.

Do not use stronger wording than the actual requirement.

## Document types

The document type describes what a page is for.

Tags describe what the page is about.

Different document types should use different structures and writing styles.

| Type | Purpose | Style |
|---|---|---|
| `architecture` | Describe system structure and boundaries | Structured and explanatory |
| `decision` | Preserve a significant choice | Factual and reflective |
| `concept` | Explain a reusable idea | Conceptual and educational |
| `software` | Describe an application and its integration | Practical and descriptive |
| `service` | Describe a running service | Operational and precise |
| `hardware` | Describe machine-specific behavior | Factual and diagnostic |
| `runbook` | Guide a repeatable procedure | Imperative and sequential |
| `investigation` | Record unresolved diagnostic work | Exploratory and evidence-based |
| `reference` | Provide exact facts or conventions | Compact and precise |
| `index` | Help navigate other pages | Terse and link-oriented |

The following structures are conventions, not rigid templates. Omit sections
that do not apply rather than filling them with empty text.

### Architecture documents

An architecture page should normally cover:

- purpose and scope;
- system boundaries;
- major components;
- relationships or data flow;
- invariants;
- integration points;
- responsibility or failure boundaries;
- related decisions.

Use an `Invariants` section when the page defines rules that other parts of the
system depend on.

Example invariants:

- `docs/` is canonical;
- Quartz is replaceable;
- stable Nixpkgs is the default package set;
- unstable packages are selected explicitly.

### Decision records

A decision record should normally contain:

- context;
- constraints;
- alternatives considered, when meaningful;
- decision;
- consequences;
- revisit conditions;
- related pages.

Do not create a decision record for every small implementation change.

Use one when preserving the reasoning is likely to matter after the current
implementation has changed.

### Concept documents

A concept page should:

- define the concept;
- explain why it matters in this system;
- separate the general idea from system-specific implementation;
- use examples where they clarify the concept;
- link to concrete software, architecture, or runbook pages.

A concept page should not become an installation guide.

### Software documents

A software page should normally cover:

- purpose;
- package source and version/update policy when relevant;
- configuration location;
- system integration;
- normal use;
- verification;
- known limitations;
- removal or replacement considerations;
- related pages.

Do not reproduce an exhaustive package definition when the Nix source already
contains it.

### Service documents

A service page should normally cover:

- purpose;
- systemd units or activation mechanism;
- dependencies and inputs;
- persistent state;
- logs;
- expected normal state;
- verification;
- common failure modes;
- recovery;
- related pages.

When a service has state that survives reboot, say where that state is stored.

### Hardware documents

A hardware page should normally cover:

- device or host context;
- observed behavior;
- relevant configuration;
- workaround or tuning;
- verification;
- known limitations;
- removal or revisit criteria;
- related investigations.

Separate a reproducible hardware fact from an unresolved diagnosis.

### Runbooks

A runbook should normally contain:

1. purpose or expected outcome;
2. prerequisites;
3. procedure;
4. verification;
5. failure handling;
6. rollback or recovery, when applicable;
7. related pages.

A runbook should help perform a task.

Move long conceptual explanations to concept, architecture, software, or service
pages and link to them.

### Investigations

An investigation page should normally contain:

- scope;
- symptoms;
- system context;
- established evidence;
- hypotheses;
- tests performed;
- interpretation;
- weakened or rejected hypotheses;
- open questions;
- next discriminating experiment;
- current conclusion;
- related pages.

For larger investigations, a hypothesis table may be useful:

| Hypothesis | State | Evidence for | Evidence against | Next discriminating test |
|---|---|---|---|---|
| Example mechanism | plausible | Reproduced symptom A | Test B did not reproduce it | Isolate condition C |

Do not assign fake numerical probabilities unless a defensible statistical
basis exists.

### Reference documents

A reference page should prioritize exactness and retrieval.

Prefer:

- compact tables;
- exact values;
- explicit names;
- definitions;
- short examples;
- links to canonical explanations.

Avoid long narrative sections when a compact representation is clearer.

### Index documents

An index page should help navigation.

Keep it:

- curated;
- terse;
- link-oriented;
- organized around likely retrieval paths.

Do not turn an index into a duplicate summary of every page.

## Headings

Use headings that describe the content beneath them.

For procedures, prefer action-oriented headings:

- `Build the configuration`
- `Activate temporarily`
- `Verify the service`
- `Recover the previous generation`

For descriptive material, prefer noun phrases or clear questions:

- `System boundaries`
- `Package selection policy`
- `Runtime architecture`
- `Known limitations`
- `Why this exists`
- `When to use this`

Avoid generic headings such as:

- `Information`
- `Details`
- `Various notes`
- `Other`
- `Miscellaneous`

Use sentence case.

Do not skip heading levels.

A page should contain one H1 heading matching the document title.

## Inline technical notation

Use backticks for literal technical identifiers, including:

- file and directory paths;
- commands;
- Nix options;
- attribute names;
- package identifiers;
- unit and service names;
- kernel parameters;
- environment variables;
- literal values;
- error codes.

Examples:

- `modules/gaming.nix`
- `services.asusd.enable`
- `crash-monitor.service`
- `nvme_core.default_ps_max_latency_us=0`
- `ETIMEDOUT`

Do not apply code formatting to ordinary product or project names unless the
literal identifier is intended.

Prefer:

> Helix uses `rust-analyzer`.

Avoid:

> `Helix` uses `rust-analyzer`.

## Commands

Commands should be complete and safe to copy.

Do not include shell prompt characters in executable command blocks.

Prefer:

```bash
sudo nixos-rebuild build --flake .#nixos
```

Avoid:

```text
$ sudo nixos-rebuild build --flake .#nixos
```

Use the language tag that matches the actual syntax:

- `bash` for Bash or POSIX shell commands;
- `nu` for Nushell-specific commands;
- `nix` for Nix expressions;
- `toml`, `yaml`, `json`, or `kdl` for configuration;
- `text` for logs and command output.

If the working directory matters, state it before the command.

Example:

> Run from the repository root:

```bash
sudo nixos-rebuild build --flake .#nixos
```

### Mutating commands

Before a command that changes persistent or important state, state what it will
change.

For temporary changes, say when the change is lost or reset.

For destructive operations, state:

- the affected scope;
- whether data will be removed;
- how to recover or roll back, when possible.

## Command output and captured evidence

Keep executable commands separate from output.

Command:

```bash
systemctl status crash-monitor.service
```

Expected relevant state:

```text
Active: active (running)
```

Distinguish example output from captured evidence.

Use wording such as:

> Expected output contains:

or:

> A captured test produced:

Do not present fabricated or simplified example output as though it were a
captured system result.

When shortening captured output, mark omissions explicitly:

```text
[... unrelated lines omitted ...]
```

Do not silently remove lines from evidence.

If omitted lines could affect the interpretation, preserve the complete output
or link to the raw capture instead.

## Examples

Place examples close to the rule or mechanism they demonstrate.

Examples should be:

- minimal enough to expose the relevant point;
- realistic enough to remain technically meaningful;
- clearly identified as examples when they are not copied from the running
  system.

When an example intentionally omits configuration, say so.

Do not use example values that could easily be mistaken for required production
values unless the surrounding text makes their role explicit.

## Lists and tables

Use numbered lists when order matters.

Use bullets when order does not matter.

Keep list items grammatically parallel where practical.

Use tables for compact comparison or reference.

Do not use a table when cells require long paragraphs or complex nested
structure.

Introduce a table with enough context to explain what is being compared.

## Links and canonicality

Prefer internal links to canonical pages over repeated explanations.

Use descriptive link text.

Prefer:

> See [[Package Source Policy]] for the stable/unstable selection rules.

Avoid:

> See [[Package Source Policy|here]].

A page should link outward when another page owns:

- a concept;
- a procedure;
- a decision;
- a detailed investigation;
- a canonical package or service explanation.

Do not create circular duplication merely to make every page self-contained.

## Source files and provenance

The `source-files` frontmatter field should list repository files that directly
implement or materially define the subject of the page.

Do not list a file merely because the page mentions it.

Use repository-relative paths.

Example:

```yaml
source-files:
  - home/development.nix
  - home/helix.nix
```

`source-files` should support maintenance workflows such as:

```text
changed source file
        ↓
documentation pages referencing that source
        ↓
candidate pages for review
```

A documentation update tool should treat `source-files` as a strong signal, not
as the only way to detect affected documentation.

Semantic references, related pages, decision records, and TODO items may also
need review.

## External sources

Use external sources when a non-obvious technical claim depends on information
outside the repository.

Prefer, in order:

1. standards or specifications;
2. upstream documentation;
3. upstream source, issue trackers, or release notes;
4. Nixpkgs package definitions;
5. reputable secondary sources.

Useful candidates for sourcing include:

- kernel behavior;
- driver capabilities;
- protocol semantics;
- hardware limitations;
- package support status;
- version-specific bugs;
- standards requirements.

Do not add citations to obvious local facts that are already established by the
repository.

When external sources materially support a page, an optional `Sources` section
may be used.

## Screenshots and diagrams

Use screenshots when the visual state itself is evidence or when the information
cannot be represented adequately as text.

Do not use screenshots merely to show command output or configuration text.

When a screenshot is version-sensitive or time-sensitive, describe the relevant
state in text so that the page remains useful if the image becomes outdated.

Use meaningful alt text.

Prefer text diagrams for simple relationships when they remain readable in raw
Markdown.

Example:

```text
Nix source
   ↓
evaluation
   ↓
derivation
   ↓
store path
```

Use rendered diagrams when topology, concurrency, or relationships become
difficult to express clearly in text.

## Callouts

Use callouts sparingly for information that deserves interruption of normal
reading flow.

Recommended meanings:

- `note` — useful supporting information;
- `important` — information that materially changes interpretation or use;
- `warning` — risk of failure, data loss, or harmful system change;
- `tip` — optional practical improvement.

Do not place ordinary paragraphs in callouts merely for emphasis.

For an active investigation or workaround, a short top-level callout may
summarize the present state.

## Workarounds and temporary configuration

Temporary configuration should state why it exists and how it will eventually be
removed.

Use one of the following sections when appropriate:

- `Removal criteria`
- `Revisit when`
- `Exit condition`

Example:

```markdown
## Removal criteria

Remove the workaround when either:

- the underlying failure is fixed by a kernel or firmware update and reproduced
  tests pass without it; or
- testing establishes that the workaround does not materially affect the
  failure.
```

Do not allow temporary configuration to become permanent merely because its
original context was lost.

## Historical context

Git is the normal source of truth for document and configuration history.

Do not maintain manual per-page changelogs.

Record historical information only when it explains the present system,
decision, limitation, or workaround.

Prefer:

```markdown
## Historical context

Taplo was originally used as the TOML language server. It was replaced after
SchemaStore catalog decoding repeatedly failed with the available Taplo
version.
```

Avoid:

```markdown
## Changelog

- 2026-08-18: Replaced Taplo.
- 2026-08-18: Added LuaLS.
- 2026-08-19: Fixed wording.
```

## Maintenance rules

When updating documentation after configuration changes:

1. read the relevant system, metadata, and style rules;
2. inspect the current source rather than relying on memory;
3. use Git history to understand what changed;
4. use `source-files` and semantic references to identify affected pages;
5. update the canonical page rather than creating duplicate explanations;
6. preserve distinctions between observation, inference, hypothesis, assumption,
   and decision;
7. update TODO items whose state changed;
8. update indexes only when navigation materially changes;
9. create a decision record only when a significant deliberate choice with
   meaningful consequences occurred;
10. state when the repository does not establish why a change was made rather
    than inventing rationale.

A documentation update is complete when the knowledge base describes the current
system accurately and unresolved uncertainty is represented explicitly.

## Related

- [[Documentation System]]
- [[Metadata Schema]]
- [[Documentation Architecture]]
