"""Immich album and tag synchronization tests using fake API data only."""

import contextlib
import importlib.util
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SPEC = importlib.util.spec_from_file_location(
    "immich_album_sync",
    Path(__file__).resolve().parents[1] / "immich-album-sync.py",
)
album_sync = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = album_sync
SPEC.loader.exec_module(album_sync)


def asset(
    asset_id,
    path,
    library_id="library-1",
    visibility="timeline",
    trashed_at=None,
):
    return {
        "id": asset_id,
        "originalPath": path,
        "libraryId": library_id,
        "visibility": visibility,
        "trashedAt": trashed_at,
    }


def managed_tags():
    return [
        {"id": "source-tag", "name": "Source", "value": "Source"},
        {
            "id": "instagram-tag",
            "parentId": "source-tag",
            "name": "Instagram",
            "value": "Source/Instagram",
        },
        {
            "id": "main-tag",
            "parentId": "source-tag",
            "name": "Main Media",
            "value": "Source/Main Media",
        },
    ]


def managed_albums():
    return [
        {
            "id": "instagram-album",
            "albumName": "Instagram",
            "description": album_sync.ALBUMS["Instagram"].description,
        },
        {
            "id": "main-album",
            "albumName": "Main Media",
            "description": album_sync.ALBUMS["Main Media"].description,
        },
    ]


class FakePagingClient(album_sync.ImmichClient):
    def __init__(self, pages):
        super().__init__("http://invalid/api", "not-a-real-key", 1)
        self.pages = iter(pages)
        self.payloads = []

    def request(self, method, path, payload=None, query=None):
        self.payloads.append(payload)
        return next(self.pages)


class FakeMutationClient(album_sync.ImmichClient):
    def __init__(self):
        super().__init__("http://invalid/api", "not-a-real-key", 1)
        self.requests = []

    def request(self, method, path, payload=None, query=None):
        self.requests.append((method, path, payload, query))
        if path == "tags":
            return [
                {
                    "id": f"created-{index}",
                    "value": value,
                }
                for index, value in enumerate(payload["tags"])
            ]
        return [{"id": asset_id, "success": True} for asset_id in payload["ids"]]


class FakeSyncClient:
    def __init__(
        self,
        archive_assets,
        albums,
        members=None,
        *,
        tags=None,
        tag_members=None,
    ):
        self.archive_assets = archive_assets
        self.albums = list(albums)
        self.members = members or {}
        self.tags = list(managed_tags() if tags is None else tags)
        if tag_members is None:
            tag_members = {"instagram-tag": set(), "main-tag": set()}
            for item in archive_assets:
                if (
                    not isinstance(item, dict)
                    or item.get("visibility") not in album_sync.MANAGED_VISIBILITIES
                    or item.get("trashedAt") is not None
                ):
                    continue
                classification = album_sync.classify_path(item.get("originalPath"))
                if classification == "Instagram":
                    tag_members["instagram-tag"].add(item["id"])
                elif classification == "Main Media":
                    tag_members["main-tag"].add(item["id"])
        self.tag_members = {
            tag_id: set(asset_ids) for tag_id, asset_ids in tag_members.items()
        }
        self.manual_tag_members = {"manual-tag": set()}
        self.created = []
        self.changes = []
        self.tag_upserts = []
        self.tag_changes = []
        self.operation_log = []
        self.filters = []

    def search_assets(self, filters):
        self.filters.append(filters)
        album_filter = filters.get("albumIds")
        tag_filter = filters.get("tagIds")
        if album_filter:
            album_id = album_filter["any"][0]
            items = [
                item if isinstance(item, dict) else asset(item, f"/unrelated/{item}")
                for item in self.members.get(album_id, set())
            ]
        elif tag_filter:
            tag_id = tag_filter["any"][0]
            items = [
                item if isinstance(item, dict) else asset(item, f"/unrelated/{item}")
                for item in self.tag_members.get(tag_id, set())
            ]
        else:
            items = self.archive_assets

        allowed_visibilities = filters.get("visibility", {}).get("in")
        if allowed_visibilities is not None:
            items = [
                item for item in items if item.get("visibility") in allowed_visibilities
            ]
        if filters.get("trashedAt", {}).get("eq", "not-requested") is None:
            items = [item for item in items if item.get("trashedAt") is None]
        yield from items

    def list_owned_albums(self):
        return self.albums

    def create_album(self, spec):
        album_id = f"new-{len(self.created)}"
        self.created.append((album_id, spec))
        return album_id

    def update_membership(self, album_id, asset_ids, *, remove):
        change = (album_id, frozenset(asset_ids), remove)
        self.changes.append(change)
        self.operation_log.append(("album", *change))

    def list_tags(self):
        return self.tags

    def upsert_managed_tags(self):
        self.tag_upserts.append(tuple(album_sync.TAGS.values()))
        self.tags = managed_tags()
        self.tag_members.setdefault("instagram-tag", set())
        self.tag_members.setdefault("main-tag", set())

    def update_tag_membership(self, tag_id, asset_ids, *, remove):
        asset_ids = frozenset(asset_ids)
        change = (tag_id, asset_ids, remove)
        self.tag_changes.append(change)
        self.operation_log.append(("tag", *change))
        members = self.tag_members.setdefault(tag_id, set())
        if remove:
            members.difference_update(asset_ids)
        else:
            members.update(asset_ids)


class ClassificationTests(unittest.TestCase):
    def test_instagram_boundary_and_recursion(self):
        self.assertEqual(
            album_sync.classify_path("/srv/media/stuff/instagram/photo.jpg"),
            "Instagram",
        )
        self.assertEqual(
            album_sync.classify_path("/srv/media/stuff/instagram/a/b/video.mp4"),
            "Instagram",
        )

    def test_main_is_complement_within_archive(self):
        for path in [
            "/srv/media/stuff/photo.jpg",
            "/srv/media/stuff/new-folder/video.mp4",
            "/srv/media/stuff/instagram-old/photo.jpg",
            "/srv/media/stuff/instagram2/photo.jpg",
        ]:
            with self.subTest(path=path):
                self.assertEqual(album_sync.classify_path(path), "Main Media")

    def test_outside_and_prefix_lookalikes_are_rejected(self):
        for path in [
            "/srv/media/stuff",
            "/srv/media/stuff-old/photo.jpg",
            "/srv/media/other/photo.jpg",
            "/srv/media/stuffinstagram/photo.jpg",
            "srv/media/stuff/photo.jpg",
        ]:
            with self.subTest(path=path):
                self.assertIsNone(album_sync.classify_path(path))

    def test_desired_requires_external_library_marker(self):
        with self.assertRaises(album_sync.SyncError):
            album_sync.desired_memberships(
                [asset("uploaded", "/srv/media/stuff/photo.jpg", library_id=None)]
            )


class ApiKeyFileTests(unittest.TestCase):
    def write_key(self, directory, mode):
        path = Path(directory) / "immich-api-key"
        path.write_text("test-api-key\n", encoding="utf-8")
        path.chmod(mode)
        return path

    def test_direct_0600_key_is_accepted(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_key(directory, 0o600)
            with mock.patch.dict(os.environ, {"CREDENTIALS_DIRECTORY": ""}):
                self.assertEqual(album_sync.read_api_key(path), "test-api-key")

    def test_direct_0644_key_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_key(directory, 0o644)
            with (
                mock.patch.dict(os.environ, {"CREDENTIALS_DIRECTORY": ""}),
                self.assertRaises(album_sync.SyncError),
            ):
                album_sync.read_api_key(path)

    def test_permissive_systemd_credential_copy_is_accepted(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_key(directory, 0o644)
            with mock.patch.dict(
                os.environ, {"CREDENTIALS_DIRECTORY": str(Path(directory))}
            ):
                self.assertEqual(album_sync.read_api_key(path), "test-api-key")

    def test_permissive_file_outside_credential_directory_is_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            credential_directory = Path(root) / "credentials"
            outside_directory = Path(root) / "outside"
            credential_directory.mkdir()
            outside_directory.mkdir()
            path = self.write_key(outside_directory, 0o644)
            with (
                mock.patch.dict(
                    os.environ,
                    {"CREDENTIALS_DIRECTORY": str(credential_directory)},
                ),
                self.assertRaises(album_sync.SyncError),
            ):
                album_sync.read_api_key(path)


class ReconciliationTests(unittest.TestCase):
    def test_delta_only(self):
        result = album_sync.reconcile({"keep", "add"}, {"keep", "remove"})
        self.assertEqual(result.additions, {"add"})
        self.assertEqual(result.removals, {"remove"})
        self.assertEqual(result.unchanged, {"keep"})

    def test_pagination_uses_returned_cursor(self):
        client = FakePagingClient(
            [
                {"assets": {"items": [asset("a", "/a")], "nextCursor": "1000"}},
                {"assets": {"items": [asset("b", "/b")], "nextCursor": None}},
            ]
        )
        self.assertEqual([item["id"] for item in client.search_assets({})], ["a", "b"])
        self.assertNotIn("cursor", client.payloads[0])
        self.assertTrue(client.payloads[0]["withStacked"])
        self.assertNotIn("withDeleted", client.payloads[0])
        self.assertEqual(client.payloads[1]["cursor"], "1000")

    def test_unmarked_same_name_is_never_adopted(self):
        spec = album_sync.ALBUMS["Instagram"]
        with self.assertRaises(album_sync.SyncError):
            album_sync.resolve_album(
                spec,
                [{"id": "human", "albumName": spec.name, "description": "mine"}],
            )

    def test_exact_marker_selects_only_managed_duplicate(self):
        spec = album_sync.ALBUMS["Instagram"]
        with contextlib.redirect_stderr(io.StringIO()):
            album_id, create = album_sync.resolve_album(
                spec,
                [
                    {"id": "human", "albumName": spec.name, "description": "mine"},
                    {
                        "id": "managed",
                        "albumName": spec.name,
                        "description": spec.description,
                    },
                ],
            )
        self.assertEqual(album_id, "managed")
        self.assertFalse(create)

    def test_dry_run_plans_without_mutation(self):
        albums = [
            {
                "id": "instagram-album",
                "albumName": "Instagram",
                "description": album_sync.ALBUMS["Instagram"].description,
            },
            {
                "id": "main-album",
                "albumName": "Main Media",
                "description": album_sync.ALBUMS["Main Media"].description,
            },
        ]
        client = FakeSyncClient(
            [
                asset("ig", "/srv/media/stuff/instagram/nested/a.jpg"),
                asset("main", "/srv/media/stuff/new/b.jpg"),
            ],
            albums,
            {"instagram-album": {"wrong"}, "main-album": {"main"}},
        )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = album_sync.sync(client, dry_run=True)
        self.assertEqual(code, 0)
        self.assertEqual(client.created, [])
        self.assertEqual(client.changes, [])
        self.assertIn("album would additions: 1", output.getvalue())
        self.assertIn("album would removals: 1", output.getvalue())

    def test_apply_adds_everywhere_before_any_removal(self):
        albums = [
            {
                "id": "instagram-album",
                "albumName": "Instagram",
                "description": album_sync.ALBUMS["Instagram"].description,
            },
            {
                "id": "main-album",
                "albumName": "Main Media",
                "description": album_sync.ALBUMS["Main Media"].description,
            },
        ]
        client = FakeSyncClient(
            [
                asset("ig", "/srv/media/stuff/instagram/a.jpg"),
                asset("main", "/srv/media/stuff/a.jpg"),
            ],
            albums,
            {"instagram-album": {"main"}, "main-album": {"ig"}},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(
            [change[2] for change in client.changes], [False, False, True, True]
        )

    def test_unchanged_run_is_idempotent_and_queries_external_archive(self):
        albums = [
            {
                "id": "instagram-album",
                "albumName": "Instagram",
                "description": album_sync.ALBUMS["Instagram"].description,
            },
            {
                "id": "main-album",
                "albumName": "Main Media",
                "description": album_sync.ALBUMS["Main Media"].description,
            },
        ]
        client = FakeSyncClient(
            [
                asset("ig", "/srv/media/stuff/instagram/a.jpg"),
                asset("main", "/srv/media/stuff/a.jpg"),
            ],
            albums,
            {"instagram-album": {"ig"}, "main-album": {"main"}},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(client.changes, [])
        self.assertEqual(
            client.filters[0],
            {
                "libraryId": {"ne": None},
                "originalPath": {"startsWith": "/srv/media/stuff/"},
                "visibility": {"in": ["timeline", "archive"]},
                "trashedAt": {"eq": None},
            },
        )

    def test_timeline_and_archive_in_both_sets_but_hidden_and_locked_excluded(self):
        albums = [
            {
                "id": "instagram-album",
                "albumName": "Instagram",
                "description": album_sync.ALBUMS["Instagram"].description,
            },
            {
                "id": "main-album",
                "albumName": "Main Media",
                "description": album_sync.ALBUMS["Main Media"].description,
            },
        ]
        client = FakeSyncClient(
            [
                asset("main-timeline", "/srv/media/stuff/main.jpg"),
                asset(
                    "main-archive",
                    "/srv/media/stuff/archived.jpg",
                    visibility="archive",
                ),
                asset("ig-timeline", "/srv/media/stuff/instagram/a.jpg"),
                asset(
                    "ig-archive",
                    "/srv/media/stuff/instagram/b.jpg",
                    visibility="archive",
                ),
                asset(
                    "main-hidden",
                    "/srv/media/stuff/component.jpg",
                    visibility="hidden",
                ),
                asset(
                    "ig-locked",
                    "/srv/media/stuff/instagram/private.jpg",
                    visibility="locked",
                ),
            ],
            albums,
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(
            client.changes,
            [
                (
                    "instagram-album",
                    frozenset({"ig-timeline", "ig-archive"}),
                    False,
                ),
                (
                    "main-album",
                    frozenset({"main-timeline", "main-archive"}),
                    False,
                ),
            ],
        )
        for filters in client.filters:
            self.assertEqual(filters["visibility"], {"in": ["timeline", "archive"]})

    def test_archived_member_in_correct_album_is_unchanged(self):
        albums = [
            {
                "id": "instagram-album",
                "albumName": "Instagram",
                "description": album_sync.ALBUMS["Instagram"].description,
            },
            {
                "id": "main-album",
                "albumName": "Main Media",
                "description": album_sync.ALBUMS["Main Media"].description,
            },
        ]
        archived = asset(
            "archived-main", "/srv/media/stuff/archived.jpg", visibility="archive"
        )
        client = FakeSyncClient(
            [archived],
            albums,
            {"main-album": [archived]},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(client.changes, [])

    def test_archived_member_in_wrong_album_is_reconciled(self):
        albums = [
            {
                "id": "instagram-album",
                "albumName": "Instagram",
                "description": album_sync.ALBUMS["Instagram"].description,
            },
            {
                "id": "main-album",
                "albumName": "Main Media",
                "description": album_sync.ALBUMS["Main Media"].description,
            },
        ]
        archived = asset(
            "archived-main", "/srv/media/stuff/archived.jpg", visibility="archive"
        )
        client = FakeSyncClient(
            [archived],
            albums,
            {"instagram-album": [archived]},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(
            client.changes,
            [
                ("main-album", frozenset({"archived-main"}), False),
                ("instagram-album", frozenset({"archived-main"}), True),
            ],
        )


class TagReconciliationTests(unittest.TestCase):
    def test_hierarchical_upsert_uses_exact_supported_payload(self):
        client = FakeMutationClient()
        client.upsert_managed_tags()
        self.assertEqual(
            client.requests,
            [
                (
                    "PUT",
                    "tags",
                    {"tags": ["Source/Instagram", "Source/Main Media"]},
                    None,
                )
            ],
        )

    def test_tag_membership_uses_conservative_batches_and_leaf_endpoint(self):
        client = FakeMutationClient()
        asset_ids = {f"asset-{index:03d}" for index in range(205)}
        client.update_tag_membership("tag-id", asset_ids, remove=False)
        self.assertEqual([request[0] for request in client.requests], ["PUT"] * 3)
        self.assertEqual(
            [request[1] for request in client.requests],
            ["tags/tag-id/assets"] * 3,
        )
        self.assertEqual(
            [len(request[2]["ids"]) for request in client.requests], [100, 100, 5]
        )

    def test_both_desired_sets_receive_only_their_source_tag(self):
        client = FakeSyncClient(
            [
                asset("ig", "/srv/media/stuff/instagram/a.jpg"),
                asset("main", "/srv/media/stuff/a.jpg"),
            ],
            managed_albums(),
            {"instagram-album": {"ig"}, "main-album": {"main"}},
            tag_members={"instagram-tag": set(), "main-tag": set()},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)

        self.assertEqual(
            client.tag_changes,
            [
                ("instagram-tag", frozenset({"ig"}), False),
                ("main-tag", frozenset({"main"}), False),
            ],
        )
        self.assertEqual(client.tag_members["instagram-tag"], {"ig"})
        self.assertEqual(client.tag_members["main-tag"], {"main"})

    def test_unrelated_manual_tags_are_preserved(self):
        client = FakeSyncClient(
            [asset("ig", "/srv/media/stuff/instagram/a.jpg")],
            managed_albums(),
            {"instagram-album": {"ig"}},
            tag_members={"instagram-tag": set(), "main-tag": set()},
        )
        client.manual_tag_members["manual-tag"] = {"ig"}
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(client.manual_tag_members["manual-tag"], {"ig"})

    def test_correct_membership_is_idempotent(self):
        client = FakeSyncClient(
            [
                asset("ig", "/srv/media/stuff/instagram/a.jpg"),
                asset("main", "/srv/media/stuff/a.jpg"),
            ],
            managed_albums(),
            {"instagram-album": {"ig"}, "main-album": {"main"}},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(client.tag_changes, [])

    def test_instagram_class_change_adds_new_tag_before_removing_old(self):
        client = FakeSyncClient(
            [asset("ig", "/srv/media/stuff/instagram/a.jpg")],
            managed_albums(),
            {"instagram-album": {"ig"}},
            tag_members={"instagram-tag": set(), "main-tag": {"ig"}},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(
            client.tag_changes,
            [
                ("instagram-tag", frozenset({"ig"}), False),
                ("main-tag", frozenset({"ig"}), True),
            ],
        )

    def test_main_class_change_adds_new_tag_before_removing_old(self):
        client = FakeSyncClient(
            [asset("main", "/srv/media/stuff/a.jpg")],
            managed_albums(),
            {"main-album": {"main"}},
            tag_members={"instagram-tag": {"main"}, "main-tag": set()},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(
            client.tag_changes,
            [
                ("main-tag", frozenset({"main"}), False),
                ("instagram-tag", frozenset({"main"}), True),
            ],
        )

    def test_visibility_and_trash_filter_but_archived_assets_remain_eligible(self):
        client = FakeSyncClient(
            [
                asset("timeline", "/srv/media/stuff/a.jpg"),
                asset(
                    "archive",
                    "/srv/media/stuff/instagram/b.jpg",
                    visibility="archive",
                ),
                asset("hidden", "/srv/media/stuff/hidden.jpg", visibility="hidden"),
                asset(
                    "locked",
                    "/srv/media/stuff/instagram/locked.jpg",
                    visibility="locked",
                ),
                asset(
                    "trashed",
                    "/srv/media/stuff/trashed.jpg",
                    trashed_at="2026-09-22T00:00:00Z",
                ),
            ],
            managed_albums(),
            tag_members={"instagram-tag": set(), "main-tag": set()},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(
            client.tag_changes,
            [
                ("instagram-tag", frozenset({"archive"}), False),
                ("main-tag", frozenset({"timeline"}), False),
            ],
        )

    def test_conflicting_source_hierarchy_fails_closed(self):
        tags = managed_tags()
        tags.append(
            {
                "id": "camera-tag",
                "parentId": "source-tag",
                "name": "Camera",
                "value": "Source/Camera",
            }
        )
        client = FakeSyncClient(
            [asset("main", "/srv/media/stuff/a.jpg")],
            managed_albums(),
            tags=tags,
        )
        with (
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(album_sync.sync(client, dry_run=False), 1)
        self.assertEqual(client.changes, [])
        self.assertEqual(client.tag_changes, [])
        self.assertEqual(client.tag_upserts, [])

    def test_dry_run_never_creates_or_mutates_tags(self):
        client = FakeSyncClient(
            [asset("main", "/srv/media/stuff/a.jpg")],
            managed_albums(),
            tags=[],
            tag_members={},
        )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(album_sync.sync(client, dry_run=True), 0)
        self.assertEqual(client.tag_upserts, [])
        self.assertEqual(client.tag_changes, [])
        self.assertIn(
            "would create managed tag Source/Main Media: yes", output.getvalue()
        )

    def test_second_unchanged_reconciliation_makes_no_tag_membership_calls(self):
        client = FakeSyncClient(
            [
                asset("ig", "/srv/media/stuff/instagram/a.jpg"),
                asset("main", "/srv/media/stuff/a.jpg"),
            ],
            managed_albums(),
            {"instagram-album": {"ig"}, "main-album": {"main"}},
            tags=[],
            tag_members={},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertTrue(client.tag_changes)
        client.tag_changes.clear()
        client.operation_log.clear()
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(client.tag_changes, [])

    def test_tag_reconciliation_does_not_change_correct_albums(self):
        client = FakeSyncClient(
            [asset("main", "/srv/media/stuff/a.jpg")],
            managed_albums(),
            {"main-album": {"main"}},
            tag_members={"instagram-tag": set(), "main-tag": set()},
        )
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(album_sync.sync(client, dry_run=False), 0)
        self.assertEqual(client.changes, [])
        self.assertEqual(
            client.tag_changes,
            [("main-tag", frozenset({"main"}), False)],
        )


if __name__ == "__main__":
    unittest.main()
