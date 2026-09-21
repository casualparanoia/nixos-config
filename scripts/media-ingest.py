#!/usr/bin/env python3

from __future__ import annotations

import argparse
import errno
import grp
import hashlib
import os
import shutil
import stat
import sys
import time
from dataclasses import dataclass
from pathlib import Path

DEFAULT_DIR_MODE = 0o2770
DEFAULT_FILE_MODE = 0o0660
DEFAULT_GROUP = "media"
HASH_CHUNK_SIZE = 8 * 1024 * 1024
PARTIAL_DIR_NAME = ".rsync-partial"


@dataclass
class Stats:
    discovered: int = 0
    discovered_bytes: int = 0
    moved: int = 0
    moved_bytes: int = 0
    renamed: int = 0
    duplicates_removed: int = 0
    duplicate_bytes: int = 0
    failed: int = 0


def octal_mode(value: str) -> int:
    try:
        mode = int(value, 8)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid octal mode: {value!r}") from exc
    if not 0 <= mode <= 0o7777:
        raise argparse.ArgumentTypeError(f"mode out of range: {value!r}")
    return mode


def human_bytes(size: int) -> str:
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    value = float(size)
    for unit in units:
        if abs(value) < 1024 or unit == units[-1]:
            return f"{value:.2f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    return f"{size} B"


def is_relative_to(path: Path, other: Path) -> bool:
    try:
        path.relative_to(other)
        return True
    except ValueError:
        return False


def validate_path(path: Path, *, group: str, mode: int, directory: bool) -> None:
    """Validate the inode, not a symlink's target; fail closed on postconditions."""
    info = path.lstat()
    expected_type = stat.S_ISDIR if directory else stat.S_ISREG
    if not expected_type(info.st_mode):
        raise ValueError(f"unexpected file type: {path}")
    if info.st_gid != grp.getgrnam(group).gr_gid:
        raise PermissionError(f"postcondition: {path} does not have group {group}")
    if stat.S_IMODE(info.st_mode) != mode:
        raise PermissionError(f"postcondition: {path} mode is not {mode:04o}")


def reject_symlink_components(path: Path) -> None:
    for component in [*reversed(path.parents), path]:
        if component.is_symlink():
            raise ValueError(f"symbolic link in path: {component}")


def normalize_path(path: Path, *, group: str, mode: int, dry_run: bool) -> None:
    if dry_run:
        return
    info = path.lstat()
    if not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
        raise ValueError(f"refusing to normalize non-regular path: {path}")
    # rename(2) preserves the inode group; setgid on the parent is insufficient.
    if info.st_gid != grp.getgrnam(group).gr_gid:
        shutil.chown(path, group=group)
    path.chmod(mode)
    validate_path(path, group=group, mode=mode, directory=stat.S_ISDIR(info.st_mode))


def ensure_directory(
    path: Path, root: Path, *, group: str, mode: int, dry_run: bool
) -> None:
    """Create each directory from root to path and enforce archive group/mode."""
    path.relative_to(root)
    reject_symlink_components(path)
    if dry_run:
        for component in [path, *path.parents]:
            if component.exists() and not component.is_dir():
                raise NotADirectoryError(str(component))
        return

    root.mkdir(parents=True, exist_ok=True)
    normalize_path(root, group=group, mode=mode, dry_run=False)

    relative = path.relative_to(root)
    current = root
    for part in relative.parts:
        current /= part
        current.mkdir(exist_ok=True)
        normalize_path(current, group=group, mode=mode, dry_run=False)


def file_digest(path: Path) -> bytes:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(HASH_CHUNK_SIZE):
            digest.update(chunk)
    return digest.digest()


def files_identical(a: Path, b: Path) -> bool:
    try:
        if a.stat().st_size != b.stat().st_size:
            return False
    except FileNotFoundError:
        return False
    return file_digest(a) == file_digest(b)


def collision_target(
    src: Path, requested: Path, policy: str, planned: dict[Path, Path]
) -> tuple[Path, bool, bool]:
    """
    Return (destination, is_renamed, is_duplicate).
    Planned targets make a dry run handle earlier simulated moves faithfully.
    """
    stem = requested.stem
    suffix = requested.suffix
    candidate = requested
    n = 0

    while candidate.exists() or candidate.is_symlink() or candidate in planned:
        if candidate.is_symlink():
            raise ValueError(f"symbolic link at destination: {candidate}")
        if policy == "error":
            raise FileExistsError(f"destination already exists: {candidate}")
        existing = planned.get(candidate, candidate)
        if policy == "dedupe" and existing.is_file() and files_identical(src, existing):
            return candidate, n > 0, True
        n += 1
        candidate = requested.with_name(f"{stem}_{n}{suffix}")

    return candidate, n > 0, False


def move_file(src: Path, target: Path, *, group: str, mode: int) -> None:
    """Install without overwriting; retain staging until output is validated.

    link/unlink has rename's cheap same-filesystem behavior but fails if the
    target appeared meanwhile. Cross-device copies use exclusive creation.
    Run with quiescent trees: this is not a defense against hostile concurrent
    replacement of directories by another writer.
    """
    if not stat.S_ISREG(src.lstat().st_mode) or src.lstat().st_nlink != 1:
        raise ValueError(f"source must be a regular file with one link: {src}")
    created = False
    try:
        try:
            os.link(src, target, follow_symlinks=False)
            created = True
        except OSError as exc:
            if exc.errno != errno.EXDEV:
                raise
            with src.open("rb") as incoming, target.open("xb") as outgoing:
                created = True
                shutil.copyfileobj(incoming, outgoing, HASH_CHUNK_SIZE)
            shutil.copystat(src, target, follow_symlinks=False)
        normalize_path(target, group=group, mode=mode, dry_run=False)
        src.unlink()
    except Exception:
        if created:
            target.unlink()  # Only the output created by this operation.
        raise


def discover_source(source: Path) -> tuple[list[Path], list[Path]]:
    files: list[Path] = []
    symlinks: list[Path] = []

    def walk_error(error: OSError) -> None:
        raise error

    # Unlike rglob, explicitly surface unreadable subtrees rather than skipping
    # them and possibly reporting a successful empty ingest.
    for parent, directories, names in os.walk(source, onerror=walk_error):
        for name in directories[:]:
            path = Path(parent) / name
            if path.is_symlink():
                symlinks.append(path)
                directories.remove(name)
        for name in names:
            path = Path(parent) / name
            info = path.lstat()
            if stat.S_ISLNK(info.st_mode):
                symlinks.append(path)
            elif stat.S_ISREG(info.st_mode) and info.st_nlink == 1:
                files.append(path)
            else:
                raise ValueError(
                    f"unsupported staging file (special file or hardlink): {path}"
                )

    files.sort()
    symlinks.sort()
    return files, symlinks


def partial_files(source: Path) -> list[Path]:
    files, symlinks = discover_source(source)
    # rsync's relative --partial-dir may appear at *any* depth in the tree.
    return [
        p for p in files + symlinks if PARTIAL_DIR_NAME in p.relative_to(source).parts
    ]


def remove_empty_directories(source: Path) -> int:
    removed = 0
    directories = sorted(
        (p for p in source.rglob("*") if p.is_dir() and not p.is_symlink()),
        key=lambda p: len(p.parts),
        reverse=True,
    )
    for directory in directories:
        try:
            directory.rmdir()
            removed += 1
        except OSError:
            pass
    return removed


def print_summary(
    stats: Stats, *, remaining: int, elapsed: float, dry_run: bool
) -> None:
    verb = "Would ingest" if dry_run else "Ingested"
    print("\nSummary")
    print(
        f"  discovered:          {stats.discovered:>8} files  ({human_bytes(stats.discovered_bytes)})"
    )
    print(
        f"  {verb.lower() + ':':<20} {stats.moved:>8} files  ({human_bytes(stats.moved_bytes)})"
    )
    print(f"  renamed collisions:  {stats.renamed:>8}")
    print(
        f"  duplicates removed:  {stats.duplicates_removed:>8} files  ({human_bytes(stats.duplicate_bytes)})"
    )
    print(f"  failed:              {stats.failed:>8}")
    print(f"  remaining files:     {remaining:>8}")
    print(f"  elapsed:             {elapsed:>8.2f} s")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Move a completed staging tree into the media archive while preserving "
            "relative paths, normalizing Unix permissions, and handling filename collisions safely."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""Examples:
  %(prog)s /srv/incoming/stuff /srv/media/stuff
  %(prog)s --dry-run /srv/incoming/stuff /srv/media/stuff
  %(prog)s --verbose --collision rename /srv/incoming/stuff /srv/media/stuff

Recommended rsync staging command:
  rsync -rt --partial --partial-dir={PARTIAL_DIR_NAME} ... /srv/incoming/stuff/

The script refuses partial files at any depth, symlinks, special files and
hardlinked staging files. Run only after rsync exits successfully, with no other
writers to either tree. Dry-run plans collisions but cannot prove write access.
Group and modes are explicitly fixed and checked, including existing duplicate
outputs. Empty staging subdirectories are removed; the source root is retained.
""",
    )
    parser.add_argument(
        "source", type=Path, metavar="SOURCE_DIR", help="completed staging directory"
    )
    parser.add_argument(
        "destination",
        type=Path,
        metavar="DESTINATION_DIR",
        help="archive destination directory",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="show what would happen without changing files",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="show every normal move in addition to collisions, duplicates, errors, and the summary",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="suppress per-file output and print only errors plus the final summary",
    )
    parser.add_argument(
        "--collision",
        choices=("dedupe", "rename", "error"),
        default="dedupe",
        help=(
            "collision policy: dedupe compares SHA-256 and removes exact incoming duplicates, "
            "otherwise renames with _N (default); rename always uses _N; error aborts"
        ),
    )
    parser.add_argument(
        "--group",
        default=DEFAULT_GROUP,
        help=f"destination group (default: {DEFAULT_GROUP})",
    )
    parser.add_argument(
        "--file-mode",
        type=octal_mode,
        default=DEFAULT_FILE_MODE,
        metavar="MODE",
        help="destination file mode in octal (default: 0660)",
    )
    parser.add_argument(
        "--dir-mode",
        type=octal_mode,
        default=DEFAULT_DIR_MODE,
        metavar="MODE",
        help="destination directory mode in octal (default: 2770)",
    )
    return parser


def run(args: argparse.Namespace, parser: argparse.ArgumentParser) -> int:

    if args.verbose and args.summary_only:
        parser.error("--verbose and --summary-only are mutually exclusive")

    # Check before resolving, which would hide symlinked CLI roots.
    reject_symlink_components(args.source.expanduser().absolute())
    reject_symlink_components(args.destination.expanduser().absolute())
    source = args.source.expanduser().resolve()
    destination = args.destination.expanduser().resolve()
    grp.getgrnam(args.group)  # Validate even in dry-run, before any mutation.

    if not source.is_dir():
        parser.error(f"source is not a directory: {source}")
    if destination.exists() and not destination.is_dir():
        parser.error(f"destination exists but is not a directory: {destination}")
    if source == destination:
        parser.error("source and destination must be different")
    if is_relative_to(destination, source):
        parser.error("destination must not be inside source")
    if is_relative_to(source, destination):
        parser.error("source must not be inside destination")

    partials = partial_files(source)
    if partials:
        print(
            f"Refusing to ingest: {len(partials)} partial file(s) remain under "
            f"{source} (including nested {PARTIAL_DIR_NAME} directories)",
            file=sys.stderr,
        )
        for path in partials[:10]:
            print(f"  {path}", file=sys.stderr)
        if len(partials) > 10:
            print(f"  ... and {len(partials) - 10} more", file=sys.stderr)
        return 2

    files, symlinks = discover_source(source)
    if symlinks:
        print(
            f"Refusing to ingest: {len(symlinks)} symbolic link(s) found in staging",
            file=sys.stderr,
        )
        for path in symlinks[:10]:
            print(f"  {path}", file=sys.stderr)
        if len(symlinks) > 10:
            print(f"  ... and {len(symlinks) - 10} more", file=sys.stderr)
        return 2

    stats = Stats(
        discovered=len(files),
        discovered_bytes=sum(path.stat().st_size for path in files),
    )

    started = time.monotonic()

    same_filesystem: bool | None = None
    if destination.exists():
        same_filesystem = source.stat().st_dev == destination.stat().st_dev

    if not args.summary_only:
        print(f"Source:      {source}")
        print(f"Destination: {destination}")
        print(
            f"Files:       {stats.discovered} ({human_bytes(stats.discovered_bytes)})"
        )
        print(f"Collision:   {args.collision}")
        print(
            f"Group/modes: {args.group}  files={args.file_mode:04o}  dirs={args.dir_mode:04o}"
        )
        if same_filesystem is True:
            print(
                "Filesystem:  same filesystem (exclusive link/unlink moves preserve the inode)"
            )
        elif same_filesystem is False:
            print(
                "Filesystem:  different filesystems (moves may copy data before removing the source)"
            )
        if args.dry_run:
            print("Mode:        DRY RUN")
        print()

    affected: dict[Path, bool] = {}
    planned: dict[Path, Path] = {}
    for src in files:
        relative = src.relative_to(source)
        requested = destination / relative

        try:
            reject_symlink_components(requested.parent)
            target, renamed, duplicate = collision_target(
                src, requested, args.collision, planned
            )
            size = src.stat().st_size

            ensure_directory(
                requested.parent,
                destination,
                group=args.group,
                mode=args.dir_mode,
                dry_run=args.dry_run,
            )
            if not args.dry_run:
                current = requested.parent
                while is_relative_to(current, destination):
                    affected[current] = True
                    current = current.parent

            if duplicate:
                if not args.summary_only:
                    print(
                        f"DUPLICATE {relative} (identical archive copy already exists)"
                    )
                if not args.dry_run:
                    normalize_path(
                        target, group=args.group, mode=args.file_mode, dry_run=False
                    )
                    affected[target] = False
                    src.unlink()
                stats.duplicates_removed += 1
                stats.duplicate_bytes += size
                continue

            if renamed:
                if not args.summary_only:
                    print(f"RENAMED   {relative} -> {target.relative_to(destination)}")
            elif args.verbose:
                print(f"MOVE      {relative}")

            if args.dry_run:
                planned[target] = src
            else:
                move_file(src, target, group=args.group, mode=args.file_mode)
                affected[target] = False
            # Count completed, validated operations, not attempted moves.
            stats.moved += 1
            stats.moved_bytes += size
            stats.renamed += int(renamed)

        except (OSError, ValueError, KeyError) as exc:
            stats.failed += 1
            print(f"ERROR     {relative}: {exc}", file=sys.stderr)
            # Fail fast; preserve the remaining staging tree for diagnosis.
            break

    if not args.dry_run:
        for path, directory in affected.items():
            try:
                validate_path(
                    path,
                    group=args.group,
                    mode=args.dir_mode if directory else args.file_mode,
                    directory=directory,
                )
            except (OSError, ValueError, KeyError) as exc:
                stats.failed += 1
                print(f"ERROR     {exc}", file=sys.stderr)
        remove_empty_directories(source)

    remaining_files, remaining_symlinks = discover_source(source)
    remaining = len(remaining_files) + len(remaining_symlinks)
    elapsed = time.monotonic() - started
    print_summary(stats, remaining=remaining, elapsed=elapsed, dry_run=args.dry_run)

    if stats.failed:
        return 1

    if not args.dry_run and remaining != 0:
        print(
            "\nERROR: ingest completed without an operation error, but staging still contains files.",
            file=sys.stderr,
        )
        return 1

    return 0


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return run(args, parser)
    except (OSError, ValueError, KeyError) as exc:
        print(f"ERROR     {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
