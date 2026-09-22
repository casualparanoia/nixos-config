#!/usr/bin/env python3
"""Reconcile path-derived Immich albums and tags through the supported API."""

from __future__ import annotations

import argparse
import json
import os
import stat
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Iterable, Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import Any

MEDIA_PREFIX = "/srv/media/stuff/"
INSTAGRAM_PREFIX = f"{MEDIA_PREFIX}instagram/"
DEFAULT_API_URL = "http://127.0.0.1:2283/api"
DEFAULT_API_KEY_FILE = "/var/lib/private-server-secrets/immich-api-key"
DEFAULT_TIMEOUT = 15.0
PAGE_SIZE = 1000
ALBUM_BATCH_SIZE = 500
TAG_BATCH_SIZE = 100
MARKER_PREFIX = "[managed-by: immich-album-sync/v1]"
MANAGED_VISIBILITIES = ("timeline", "archive")
SOURCE_TAG_ROOT = "Source"


@dataclass(frozen=True)
class AlbumSpec:
    name: str
    description: str


ALBUMS = {
    "Instagram": AlbumSpec(
        name="Instagram",
        description=(
            f"{MARKER_PREFIX}\nAssets in the external library below {INSTAGRAM_PREFIX}"
        ),
    ),
    "Main Media": AlbumSpec(
        name="Main Media",
        description=(
            f"{MARKER_PREFIX}\n"
            f"Assets in the external library below {MEDIA_PREFIX}, excluding "
            f"{INSTAGRAM_PREFIX}"
        ),
    ),
}

TAGS = {
    "Instagram": "Source/Instagram",
    "Main Media": "Source/Main Media",
}


class SyncError(RuntimeError):
    """A safe, operator-actionable synchronization failure."""


@dataclass(frozen=True)
class Reconciliation:
    additions: frozenset[str]
    removals: frozenset[str]
    unchanged: frozenset[str]


@dataclass
class AlbumPlan:
    spec: AlbumSpec
    album_id: str | None
    reconciliation: Reconciliation
    needs_creation: bool = False


@dataclass
class TagPlan:
    classification: str
    value: str
    tag_id: str | None
    reconciliation: Reconciliation
    needs_creation: bool = False


def classify_path(original_path: str) -> str | None:
    """Return the managed album for an exact archive path boundary."""
    if not isinstance(original_path, str) or not original_path.startswith(MEDIA_PREFIX):
        return None
    if original_path.startswith(INSTAGRAM_PREFIX):
        return "Instagram"
    return "Main Media"


def desired_memberships(assets: Iterable[dict[str, Any]]) -> dict[str, set[str]]:
    desired = {name: set() for name in ALBUMS}
    seen: set[str] = set()
    for asset in assets:
        try:
            asset_id = asset["id"]
            original_path = asset["originalPath"]
        except (KeyError, TypeError) as exc:
            raise SyncError("Immich returned an asset without id/originalPath") from exc
        if not isinstance(asset_id, str) or not asset_id:
            raise SyncError("Immich returned an invalid asset ID")
        if asset_id in seen:
            raise SyncError(f"Immich search returned duplicate asset ID {asset_id}")
        seen.add(asset_id)
        album_name = classify_path(original_path)
        if album_name is None:
            raise SyncError(
                f"Immich returned an out-of-scope path for the archive query: "
                f"{original_path!r}"
            )
        # A non-null library ID is the API's external-library discriminator.
        if not asset.get("libraryId"):
            raise SyncError(
                f"Immich returned non-library asset {asset_id} for the external-library query"
            )
        desired[album_name].add(asset_id)
    return desired


def reconcile(desired: set[str], current: set[str]) -> Reconciliation:
    return Reconciliation(
        additions=frozenset(desired - current),
        removals=frozenset(current - desired),
        unchanged=frozenset(desired & current),
    )


def managed_visibility_filter() -> dict[str, Any]:
    """Return the common active, user-visible asset universe."""
    return {
        "visibility": {"in": list(MANAGED_VISIBILITIES)},
        "trashedAt": {"eq": None},
    }


def chunks(values: Iterable[str], size: int) -> Iterator[list[str]]:
    batch: list[str] = []
    for value in sorted(values):
        batch.append(value)
        if len(batch) == size:
            yield batch
            batch = []
    if batch:
        yield batch


class ImmichClient:
    def __init__(self, base_url: str, api_key: str, timeout: float):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.timeout = timeout

    def request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any] | None = None,
        query: dict[str, str] | None = None,
    ) -> Any:
        url = f"{self.base_url}/{path.lstrip('/')}"
        if query:
            url = f"{url}?{urllib.parse.urlencode(query)}"
        body = None if payload is None else json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            url,
            data=body,
            method=method,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "x-api-key": self.api_key,
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                contents = response.read()
        except urllib.error.HTTPError as exc:
            detail = exc.read(4096).decode("utf-8", errors="replace")
            raise SyncError(
                f"Immich API {method} {path} returned HTTP {exc.code}: {detail}"
            ) from exc
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            raise SyncError(f"Immich API {method} {path} failed: {exc}") from exc
        if not contents:
            return None
        try:
            return json.loads(contents)
        except json.JSONDecodeError as exc:
            raise SyncError(
                f"Immich API {method} {path} returned invalid JSON"
            ) from exc

    def search_assets(self, filters: dict[str, Any]) -> Iterator[dict[str, Any]]:
        cursor: str | None = None
        seen_cursors: set[str] = set()
        while True:
            payload: dict[str, Any] = {
                "size": PAGE_SIZE,
                "withStacked": True,
                "filter": filters,
            }
            if cursor is not None:
                payload["cursor"] = cursor
            response = self.request("POST", "search/metadata", payload)
            try:
                page = response["assets"]
                items = page["items"]
                next_cursor = page["nextCursor"]
            except (KeyError, TypeError) as exc:
                raise SyncError("Immich returned an invalid search page") from exc
            if not isinstance(items, list):
                raise SyncError("Immich returned non-list search items")
            if any(not isinstance(item, dict) for item in items):
                raise SyncError("Immich returned an invalid asset item")
            yield from items
            if next_cursor is None:
                return
            if not isinstance(next_cursor, str) or not next_cursor:
                raise SyncError("Immich returned an invalid search cursor")
            if next_cursor in seen_cursors:
                raise SyncError("Immich repeated a search cursor")
            seen_cursors.add(next_cursor)
            cursor = next_cursor

    def list_owned_albums(self) -> list[dict[str, Any]]:
        albums = self.request("GET", "albums", query={"isOwned": "true"})
        if not isinstance(albums, list):
            raise SyncError("Immich returned an invalid album list")
        if any(not isinstance(album, dict) for album in albums):
            raise SyncError("Immich returned an invalid album item")
        return albums

    def create_album(self, spec: AlbumSpec) -> str:
        album = self.request(
            "POST",
            "albums",
            {"albumName": spec.name, "description": spec.description},
        )
        album_id = album.get("id") if isinstance(album, dict) else None
        if not isinstance(album_id, str) or not album_id:
            raise SyncError(f"Immich returned no ID when creating {spec.name!r}")
        return album_id

    def update_membership(
        self, album_id: str, asset_ids: Iterable[str], *, remove: bool
    ) -> None:
        method = "DELETE" if remove else "PUT"
        for batch in chunks(asset_ids, ALBUM_BATCH_SIZE):
            result = self.request(method, f"albums/{album_id}/assets", {"ids": batch})
            if not isinstance(result, list):
                raise SyncError("Immich returned an invalid bulk membership response")
            if any(not isinstance(item, dict) for item in result):
                raise SyncError("Immich returned an invalid bulk membership item")
            failures = [item for item in result if not item.get("success", False)]
            if failures:
                raise SyncError(
                    f"Immich rejected {len(failures)} of {len(batch)} album membership changes"
                )

    def list_tags(self) -> list[dict[str, Any]]:
        tags = self.request("GET", "tags")
        if not isinstance(tags, list):
            raise SyncError("Immich returned an invalid tag list")
        seen_ids: set[str] = set()
        seen_values: set[str] = set()
        for tag in tags:
            if not isinstance(tag, dict):
                raise SyncError("Immich returned an invalid tag item")
            tag_id = tag.get("id")
            value = tag.get("value")
            if not isinstance(tag_id, str) or not tag_id:
                raise SyncError("Immich returned a tag without a valid ID")
            if not isinstance(value, str) or not value:
                raise SyncError(f"Immich returned tag {tag_id!r} without a valid value")
            if tag_id in seen_ids or value in seen_values:
                raise SyncError("Immich returned duplicate tag IDs or values")
            seen_ids.add(tag_id)
            seen_values.add(value)
        return tags

    def upsert_managed_tags(self) -> None:
        result = self.request("PUT", "tags", {"tags": list(TAGS.values())})
        if not isinstance(result, list) or any(
            not isinstance(tag, dict) for tag in result
        ):
            raise SyncError("Immich returned an invalid tag upsert response")
        returned = {tag.get("value") for tag in result}
        if returned != set(TAGS.values()):
            raise SyncError("Immich did not return both requested managed tag leaves")
        if any(not isinstance(tag.get("id"), str) or not tag["id"] for tag in result):
            raise SyncError("Immich returned a managed tag without a valid ID")

    def update_tag_membership(
        self, tag_id: str, asset_ids: Iterable[str], *, remove: bool
    ) -> None:
        method = "DELETE" if remove else "PUT"
        for batch in chunks(asset_ids, TAG_BATCH_SIZE):
            result = self.request(method, f"tags/{tag_id}/assets", {"ids": batch})
            if not isinstance(result, list):
                raise SyncError("Immich returned an invalid bulk tag response")
            if any(not isinstance(item, dict) for item in result):
                raise SyncError("Immich returned an invalid bulk tag item")
            failures = [item for item in result if not item.get("success", False)]
            if failures:
                raise SyncError(
                    f"Immich rejected {len(failures)} of {len(batch)} tag membership changes"
                )


def resolve_album(
    spec: AlbumSpec, albums: Iterable[dict[str, Any]]
) -> tuple[str | None, bool]:
    same_name = [album for album in albums if album.get("albumName") == spec.name]
    managed = [
        album for album in same_name if album.get("description") == spec.description
    ]
    if len(managed) > 1:
        raise SyncError(
            f"multiple managed albums named {spec.name!r}; refusing ambiguous ownership"
        )
    if len(managed) == 1:
        album_id = managed[0].get("id")
        if not isinstance(album_id, str) or not album_id:
            raise SyncError(f"managed album {spec.name!r} has no valid ID")
        if len(same_name) > 1:
            print(
                f"warning: unrelated duplicate album(s) also use {spec.name!r}; "
                "only the marked album will be managed",
                file=sys.stderr,
            )
        return album_id, False
    if same_name:
        raise SyncError(
            f"album {spec.name!r} already exists without the ownership marker; "
            "refusing to take it over"
        )
    return None, True


def current_album_members(client: ImmichClient, album_id: str) -> set[str]:
    members: set[str] = set()
    filters = {
        "albumIds": {"any": [album_id]},
        **managed_visibility_filter(),
    }
    for asset in client.search_assets(filters):
        asset_id = asset.get("id")
        if not isinstance(asset_id, str) or not asset_id:
            raise SyncError("Immich returned an invalid album member")
        if asset_id in members:
            raise SyncError(f"Immich returned duplicate album member {asset_id}")
        members.add(asset_id)
    return members


def resolve_managed_tags(
    tags: Iterable[dict[str, Any]],
) -> tuple[dict[str, str | None], bool]:
    """Resolve the reserved Source hierarchy or fail before taking it over."""
    namespace = [
        tag
        for tag in tags
        if tag.get("value") == SOURCE_TAG_ROOT
        or str(tag.get("value", "")).startswith(f"{SOURCE_TAG_ROOT}/")
    ]
    empty = {classification: None for classification in TAGS}
    if not namespace:
        return empty, True

    expected_values = {SOURCE_TAG_ROOT, *TAGS.values()}
    by_value: dict[str, list[dict[str, Any]]] = {}
    for tag in namespace:
        by_value.setdefault(tag["value"], []).append(tag)
    if set(by_value) != expected_values or any(
        len(items) != 1 for items in by_value.values()
    ):
        found = ", ".join(sorted(by_value))
        raise SyncError(
            "pre-existing Source tag hierarchy is not exactly the managed "
            f"hierarchy; refusing to take it over (found: {found})"
        )

    root = by_value[SOURCE_TAG_ROOT][0]
    root_id = root.get("id")
    if root.get("parentId") is not None:
        raise SyncError("managed Source tag root unexpectedly has a parent")

    resolved: dict[str, str | None] = {}
    for classification, value in TAGS.items():
        tag = by_value[value][0]
        if tag.get("parentId") != root_id:
            raise SyncError(
                f"tag {value!r} is not a direct child of the managed Source root"
            )
        resolved[classification] = tag["id"]
    return resolved, False


def current_tag_members(client: ImmichClient, tag_id: str) -> set[str]:
    members: set[str] = set()
    filters = {
        "tagIds": {"any": [tag_id]},
        **managed_visibility_filter(),
    }
    for asset in client.search_assets(filters):
        asset_id = asset.get("id")
        if not isinstance(asset_id, str) or not asset_id:
            raise SyncError("Immich returned an invalid tag member")
        if asset_id in members:
            raise SyncError(f"Immich returned duplicate tag member {asset_id}")
        members.add(asset_id)
    return members


def sync(client: ImmichClient, *, dry_run: bool) -> int:
    archive_filter = {
        "libraryId": {"ne": None},
        "originalPath": {"startsWith": MEDIA_PREFIX},
        **managed_visibility_filter(),
    }
    assets = list(client.search_assets(archive_filter))
    desired = desired_memberships(assets)
    albums = client.list_owned_albums()
    tags = client.list_tags()

    resolved_albums: dict[str, tuple[str | None, bool]] = {}
    ownership_errors: list[str] = []
    for name, spec in ALBUMS.items():
        try:
            resolved_albums[name] = resolve_album(spec, albums)
        except SyncError as exc:
            ownership_errors.append(str(exc))
    try:
        resolved_tags, tags_need_creation = resolve_managed_tags(tags)
    except SyncError as exc:
        ownership_errors.append(str(exc))

    if ownership_errors:
        for error in ownership_errors:
            print(f"error: {error}", file=sys.stderr)
        print_summary(len(assets), desired, [], [], len(ownership_errors))
        return 1

    if not dry_run:
        for name, (album_id, needs_creation) in list(resolved_albums.items()):
            if needs_creation:
                album_id = client.create_album(ALBUMS[name])
                resolved_albums[name] = (album_id, False)
                print(f"created managed album {name!r} ({album_id})")
        if tags_need_creation:
            client.upsert_managed_tags()
            resolved_tags, still_missing = resolve_managed_tags(client.list_tags())
            if still_missing:
                raise SyncError("managed tags remain missing after their upsert")
            tags_need_creation = False
            print("created managed tag hierarchy 'Source'")

    album_plans: list[AlbumPlan] = []
    for name, spec in ALBUMS.items():
        album_id, needs_creation = resolved_albums[name]
        current = set() if album_id is None else current_album_members(client, album_id)
        album_plans.append(
            AlbumPlan(
                spec=spec,
                album_id=album_id,
                reconciliation=reconcile(desired[name], current),
                needs_creation=needs_creation,
            )
        )

    tag_plans: list[TagPlan] = []
    for classification, value in TAGS.items():
        tag_id = resolved_tags[classification]
        current = set() if tag_id is None else current_tag_members(client, tag_id)
        tag_plans.append(
            TagPlan(
                classification=classification,
                value=value,
                tag_id=tag_id,
                reconciliation=reconcile(desired[classification], current),
                needs_creation=tags_need_creation,
            )
        )

    errors = 0
    if not dry_run:
        # Complete every addition before any removal so assets changing class
        # never have a gap in either managed view.
        for plan in album_plans:
            if not plan.reconciliation.additions:
                continue
            try:
                assert plan.album_id is not None
                client.update_membership(
                    plan.album_id, plan.reconciliation.additions, remove=False
                )
            except (AssertionError, SyncError) as exc:
                errors += 1
                print(f"error: additions for {plan.spec.name}: {exc}", file=sys.stderr)
        for plan in tag_plans:
            if not plan.reconciliation.additions:
                continue
            try:
                assert plan.tag_id is not None
                client.update_tag_membership(
                    plan.tag_id, plan.reconciliation.additions, remove=False
                )
            except (AssertionError, SyncError) as exc:
                errors += 1
                print(f"error: additions for tag {plan.value}: {exc}", file=sys.stderr)
        if errors == 0:
            for plan in album_plans:
                if not plan.reconciliation.removals:
                    continue
                try:
                    assert plan.album_id is not None
                    client.update_membership(
                        plan.album_id, plan.reconciliation.removals, remove=True
                    )
                except (AssertionError, SyncError) as exc:
                    errors += 1
                    print(
                        f"error: removals for {plan.spec.name}: {exc}",
                        file=sys.stderr,
                    )
            for plan in tag_plans:
                if not plan.reconciliation.removals:
                    continue
                try:
                    assert plan.tag_id is not None
                    client.update_tag_membership(
                        plan.tag_id, plan.reconciliation.removals, remove=True
                    )
                except (AssertionError, SyncError) as exc:
                    errors += 1
                    print(
                        f"error: removals for tag {plan.value}: {exc}",
                        file=sys.stderr,
                    )

    print_summary(
        len(assets),
        desired,
        album_plans,
        tag_plans,
        errors,
        dry_run=dry_run,
    )
    return 1 if errors else 0


def print_summary(
    scanned: int,
    desired: dict[str, set[str]],
    album_plans: Iterable[AlbumPlan],
    tag_plans: Iterable[TagPlan],
    errors: int,
    *,
    dry_run: bool = False,
) -> None:
    album_plans_by_name = {plan.spec.name: plan for plan in album_plans}
    tag_plans_by_name = {plan.classification: plan for plan in tag_plans}
    print(f"mode: {'dry-run' if dry_run else 'apply'}")
    print(f"scanned: {scanned}")
    for name in ALBUMS:
        print(f"matching {name}: {len(desired[name])}")
        album_plan = album_plans_by_name.get(name)
        if album_plan is None:
            continue
        prefix = "would " if dry_run else ""
        if album_plan.needs_creation:
            print(f"  {prefix}create managed album: yes")
        print(f"  album {prefix}additions: {len(album_plan.reconciliation.additions)}")
        print(f"  album {prefix}removals: {len(album_plan.reconciliation.removals)}")
        print(f"  album unchanged: {len(album_plan.reconciliation.unchanged)}")
        tag_plan = tag_plans_by_name.get(name)
        if tag_plan is None:
            continue
        if tag_plan.needs_creation:
            print(f"  {prefix}create managed tag {tag_plan.value}: yes")
        print(f"  tag {prefix}additions: {len(tag_plan.reconciliation.additions)}")
        print(f"  tag {prefix}removals: {len(tag_plan.reconciliation.removals)}")
        print(f"  tag unchanged: {len(tag_plan.reconciliation.unchanged)}")
    print(f"errors: {errors}")


def is_systemd_credential_path(path: Path) -> bool:
    """Return whether path is a direct child of systemd's credential directory."""
    directory = os.environ.get("CREDENTIALS_DIRECTORY")
    if not directory:
        return False
    credential_directory = Path(directory)
    if not path.is_absolute() or not credential_directory.is_absolute():
        return False
    return Path(os.path.abspath(path.parent)) == Path(
        os.path.abspath(credential_directory)
    )


def read_api_key(path: Path) -> str:
    try:
        info = path.stat()
    except OSError as exc:
        raise SyncError(f"cannot stat API key file {path}: {exc}") from exc
    if not stat.S_ISREG(info.st_mode):
        raise SyncError(f"API key path is not a regular file: {path}")
    if stat.S_IMODE(info.st_mode) & 0o077 and not is_systemd_credential_path(path):
        raise SyncError(f"API key file must not be group/world accessible: {path}")
    try:
        value = path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise SyncError(f"cannot read API key file {path}: {exc}") from exc
    if not value:
        raise SyncError(f"API key file is empty: {path}")
    return value


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="report without writes")
    parser.add_argument(
        "--api-url",
        default=os.environ.get("IMMICH_API_URL", DEFAULT_API_URL),
        help=f"Immich API base URL (default: {DEFAULT_API_URL})",
    )
    parser.add_argument(
        "--api-key-file",
        type=Path,
        default=Path(os.environ.get("IMMICH_API_KEY_FILE", DEFAULT_API_KEY_FILE)),
        help="root-only file containing an Immich API key",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=DEFAULT_TIMEOUT,
        help=f"per-request timeout in seconds (default: {DEFAULT_TIMEOUT:g})",
    )
    args = parser.parse_args(argv)
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        key = read_api_key(args.api_key_file)
        client = ImmichClient(args.api_url, key, args.timeout)
        return sync(client, dry_run=args.dry_run)
    except SyncError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
