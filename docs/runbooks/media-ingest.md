---
title: Media Transfer and Ingest
description: Stage transfers over the direct Ethernet link and safely ingest into the shared originals archive.
type: runbook
status: active
tags:
  - media
  - rsync
  - gl702zc
source-files:
  - scripts/media-ingest.py
  - scripts/tests/test_media_ingest.py
  - hosts/gl702zc/media.nix
---

# Media Transfer and Ingest

Transfer into `/srv/incoming`, then explicitly ingest completed files into the
single shared archive. Never use the real archive as an automated test fixture.
The ownership model is described in [[services/private-server|GL702ZC Private Server]].
There is currently no complete independent backup of the originals archive.
Ingestion moves data; neither it nor the photo applications' databases provide
an independent media backup.

## Prerequisites

- On the desktop, configure the dedicated Ethernet end as `10.42.0.1/24`, without
  gateway or DNS; GL702ZC provides `10.42.0.2/24` through NetworkManager.
- Confirm `ssh casua@10.42.0.2` works. NetBird can substitute for the target IP
  when the cable is absent, at lower measured throughput.
- On GL702ZC, `id` in the ingest session must include `media`; log in again after
  adding group membership. Use the normal `casua` account, not root.
- Stop transfers and other archive writers before ingestion. This is a
  single-writer workflow, not a concurrent synchronization service.

## Stage a transfer

This writes only into staging. Replace `SOURCE/` with the source directory;
the trailing slash transfers its contents.

```bash
rsync -rt \
  --partial \
  --partial-dir=.rsync-partial \
  --info=progress2 \
  --human-readable \
  --chmod=D2770,F0660 \
  SOURCE/ \
  casua@10.42.0.2:/srv/incoming/stuff/
```

Wait for rsync to exit successfully. `--partial-dir` keeps interrupted files out
of the completed-file namespace and lets a rerun resume them. Relative partial
directories can occur at **any depth**. The helper refuses all ingestion while
any contains files; do not bypass the check by renaming partial files.

## Preview, then ingest

From the repository root on GL702ZC:

```bash
python3 scripts/media-ingest.py --help
python3 scripts/media-ingest.py --dry-run /srv/incoming/stuff /srv/media/stuff
```

Dry-run hashes actual same-name/same-size collisions and simulates earlier moves
for later collision decisions. It does not create directories, change modes or
group, move files, delete duplicates, or clean staging. It cannot prove that a
later write/chown will be permitted.

The following command **moves staging data into the archive**, fixes the group
and modes of affected output paths, and removes identical incoming duplicates:

```bash
python3 scripts/media-ingest.py --verbose /srv/incoming/stuff /srv/media/stuff
```

Review the summary and exit status. Default `--collision dedupe` compares SHA-256
only for actual equal-size filename collisions, removes identical staging copies,
and suffixes different content with `_N`. `--collision rename` retains both copies
even if identical; `--collision error` fails at the first occupied name.
`--summary-only` suppresses per-file messages but not errors. Existing duplicate
outputs are normalized and checked **before** removing their staging copies.

After a successful run, request external-library scanning/metadata refresh in
Immich or originals indexing in PhotoPrism as a deliberate application action.
The ingest helper does not trigger either application or manage their databases.

## Why group normalization is explicit

A same-filesystem `shutil.move()` usually becomes `rename(2)`. That preserves
the inode owner/group: a destination directory's setgid bit does **not** turn
an existing `casua:users` file into `casua:media`. This caused real Immich ffprobe
permission failures in the original transfer experiment.

The helper explicitly sets the destination group and exact file/directory modes,
then validates the inode type, group, and mode. It rechecks every affected output
before reporting success. It touches only directories on affected output paths
and moved/duplicate files, not unrelated archive contents.

For no-overwrite installation, same-filesystem moves now use an exclusive
hardlink followed by unlinking staging **after validation**. This preserves the
same inode and cheap move behavior, including the need for explicit group repair.
Cross-device moves use an exclusive copy, preserve timestamps, validate, and
only then remove staging. On failure, the helper retains staging and attempts
to remove its newly created output. It never replaces a target that appears
after collision selection.

During a same-filesystem move, staging and destination are temporarily two names
for **the same inode**. Group/mode normalization therefore affects both names
before staging is unlinked. If normalization or the staging unlink fails,
retaining staging does not roll back its metadata: the surviving file may have
partially or fully normalized group/mode, with its contents retained. A failed
staging unlink normally removes the new destination link and reports failure,
not a successful move. If that cleanup also fails, both names can remain; inspect
the exact pair before retrying. Cross-device copies do not share this inode.

## Failure handling

- Exit **0** means the requested operation (or dry-run) passed its checks.
  Exit **1** reports an ingest/postcondition failure; exit **2** reports invalid
  input or a discovery/preflight error. Failed operations are not counted as
  successfully ingested or deduplicated.
- Symlinks in staging, CLI roots or destination path components are refused.
  Special files and hardlinked staging files are also refused. Do not silently
  dereference them into the archive.
- Only empty staging subdirectories are cleaned up. The staging root is retained.
- Fix the reported permission, space or collision problem, inspect the named
  outputs and remaining staging files, then rerun a dry-run. Already completed
  moves remain in the archive. A final postcondition failure can refer to an
  earlier completed output; do not assume rerunning only staging will repair it.
- The helper is not crash-transactional. Interruption between link and unlink
  can leave two names for one inode with metadata changes already applied;
  identify that exact pair before removing
  the redundant staging link. Hardlink preflight deliberately refuses to guess.
- Keep both trees quiescent. Exclusive output creation prevents accidental file
  overwrites, but path traversal is not a security boundary against a hostile
  concurrent writer replacing directory components.
- Never run a blanket archive permission repair as routine ingestion. The
  historical recursive group/mode repair has already been performed.

## Automated verification

Run from the repository root; tests create only temporary data:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/tests -v
ruff check scripts/media-ingest.py scripts/tests/test_media_ingest.py
```

Coverage includes collisions/dedupe, simulated dry-run collisions, partial files
at nested depths, symlinks, special files/hardlinks, group/mode postconditions,
cleanup, copy and permission failures, and late destination creation. The real
group-change test uses a second group already available to the test user, or
skips when no such group exists. Cross-device behavior uses an injected `EXDEV`
so it does not require a second mounted filesystem or root.
