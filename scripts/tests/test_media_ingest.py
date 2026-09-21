"""Archive safety regressions; all data lives in disposable temporary trees."""

import contextlib
import errno
import grp
import importlib.util
import io
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "media_ingest", Path(__file__).resolve().parents[1] / "media-ingest.py"
)
ingest = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = ingest
SPEC.loader.exec_module(ingest)


class IngestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="media-ingest-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "incoming"
        self.destination = self.root / "archive"
        self.source.mkdir()
        self.group = grp.getgrgid(os.getgid()).gr_name

    def file(self, relative, content=b"incoming", *, archive=False):
        root = self.destination if archive else self.source
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        return path

    def run_ingest(self, *flags):
        out, err = io.StringIO(), io.StringIO()
        argv = [
            "media-ingest.py",
            str(self.source),
            str(self.destination),
            "--group",
            self.group,
            *flags,
        ]
        with (
            patch.object(sys, "argv", argv),
            contextlib.redirect_stdout(out),
            contextlib.redirect_stderr(err),
        ):
            code = ingest.main()
        return code, out.getvalue(), err.getvalue()

    def assert_modes(self, path, directory=False):
        info = path.stat()
        self.assertEqual(info.st_gid, grp.getgrnam(self.group).gr_gid)
        self.assertEqual(stat.S_IMODE(info.st_mode), 0o2770 if directory else 0o660)

    def test_move_normalizes_file_and_all_output_directories(self):
        src = self.file("year/month/photo.jpg")
        src.chmod(0o600)
        inode = src.stat().st_ino
        os.utime(src, (123456789, 123456789))
        code, out, err = self.run_ingest("--verbose")
        self.assertEqual(code, 0, err)
        target = self.destination / "year/month/photo.jpg"
        self.assertEqual(target.stat().st_ino, inode)
        self.assertEqual(target.stat().st_mtime, 123456789)
        self.assert_modes(target)
        for path in [self.destination, target.parent.parent, target.parent]:
            self.assert_modes(path, directory=True)
        self.assertEqual(list(self.source.iterdir()), [])
        self.assertIn("MOVE", out)

    def test_group_changes_despite_same_filesystem_inode(self):
        src = self.file("photo.jpg")
        groups = [g for g in os.getgroups() if g != src.stat().st_gid]
        if not groups:
            self.skipTest("requires membership in a second group")
        self.group = grp.getgrgid(groups[0]).gr_name
        code, _, err = self.run_ingest()
        self.assertEqual(code, 0, err)
        self.assert_modes(self.destination / "photo.jpg")

    def test_hashes_only_actual_same_size_collisions(self):
        self.file("a.jpg", b"one")
        self.file("b.jpg", b"two")
        self.file("b.jpg", b"old", archive=True)
        self.file("c.jpg", b"long")
        self.file("c.jpg", b"x", archive=True)
        with patch.object(ingest, "file_digest", wraps=ingest.file_digest) as digest:
            code, _, err = self.run_ingest()
        self.assertEqual(code, 0, err)
        self.assertEqual(digest.call_count, 2)
        self.assertEqual((self.destination / "b.jpg").read_bytes(), b"old")
        self.assertEqual((self.destination / "b_1.jpg").read_bytes(), b"two")

    def test_identical_duplicate_normalizes_retained_output(self):
        self.file("a.jpg")
        retained = self.file("a.jpg", archive=True)
        retained.chmod(0o600)
        code, out, err = self.run_ingest()
        self.assertEqual(code, 0, err)
        self.assertIn("DUPLICATE", out)
        self.assert_modes(retained)
        self.assertFalse((self.source / "a.jpg").exists())

    def test_duplicate_at_numbered_collision(self):
        self.file("a.jpg")
        self.file("a.jpg", b"older", archive=True)
        self.file("a_1.jpg", archive=True)
        self.assertEqual(self.run_ingest()[0], 0)
        self.assertFalse((self.destination / "a_2.jpg").exists())

    def test_rename_policy_retains_identical_data(self):
        self.file("a.jpg")
        self.file("a.jpg", archive=True)
        code, _, err = self.run_ingest("--collision", "rename")
        self.assertEqual(code, 0, err)
        self.assertTrue((self.destination / "a_1.jpg").exists())

    def test_error_policy_is_fail_fast_and_counts_no_move(self):
        self.file("a.jpg")
        self.file("b.jpg")
        self.file("a.jpg", b"older", archive=True)
        code, out, err = self.run_ingest("--collision", "error", "--summary-only")
        self.assertEqual(code, 1)
        self.assertIn("already exists", err)
        self.assertRegex(out, r"ingested:\s+0 files")
        self.assertTrue((self.source / "b.jpg").exists())

    def test_directory_collision_is_renamed_not_moved_into_directory(self):
        self.file("a.jpg")
        (self.destination / "a.jpg").mkdir(parents=True)
        code, _, err = self.run_ingest()
        self.assertEqual(code, 0, err)
        self.assertEqual(list((self.destination / "a.jpg").iterdir()), [])
        self.assertTrue((self.destination / "a_1.jpg").is_file())

    def test_dry_run_preserves_content_modes_and_directories(self):
        src = self.file("nested/a.jpg")
        target = self.file("nested/a.jpg", archive=True)
        before = (src.stat(), target.stat(), target.parent.stat())
        code, out, err = self.run_ingest("--dry-run")
        self.assertEqual(code, 0, err)
        self.assertIn("Would", out.replace("would", "Would"))
        after = (src.stat(), target.stat(), target.parent.stat())
        for old, new in zip(before, after):
            self.assertEqual(
                (old.st_mode, old.st_gid, old.st_mtime_ns, old.st_ctime_ns),
                (new.st_mode, new.st_gid, new.st_mtime_ns, new.st_ctime_ns),
            )

    def test_dry_run_simulates_sequential_name_collisions(self):
        self.file("a.jpg", b"new")
        self.file("a_1.jpg", b"new")
        self.file("a.jpg", b"old", archive=True)
        code, out, err = self.run_ingest("--dry-run")
        self.assertEqual(code, 0, err)
        self.assertIn("DUPLICATE a_1.jpg", out)
        self.assertFalse((self.destination / "a_1.jpg").exists())
        code, actual, err = self.run_ingest()
        self.assertEqual(code, 0, err)
        self.assertIn("DUPLICATE a_1.jpg", actual)

    def test_dry_run_does_not_create_destination(self):
        self.file("a.jpg")
        self.assertEqual(self.run_ingest("-n")[0], 0)
        self.assertFalse(self.destination.exists())

    def test_nested_partial_files_block_all_ingestion(self):
        self.file("ready.jpg")
        self.file("year/.rsync-partial/incomplete.mp4")
        code, _, err = self.run_ingest()
        self.assertEqual(code, 2)
        self.assertIn("partial", err)
        self.assertFalse(self.destination.exists())

    def test_empty_partial_directory_is_removed(self):
        (self.source / "nested/.rsync-partial").mkdir(parents=True)
        self.file("ready.jpg")
        self.assertEqual(self.run_ingest()[0], 0)
        self.assertEqual(list(self.source.iterdir()), [])

    def test_source_symlinks_are_refused_including_broken_and_directory(self):
        for target in [self.root / "missing", self.root, self.file("real.jpg")]:
            with self.subTest(target=target):
                link = self.source / "link"
                link.symlink_to(target)
                code, _, err = self.run_ingest()
                self.assertEqual(code, 2)
                self.assertIn("symbolic link", err)
                self.assertFalse(self.destination.exists())
                link.unlink()

    def test_destination_symlink_and_parent_symlink_are_refused(self):
        self.file("nested/a.jpg")
        outside = self.root / "outside"
        outside.mkdir()
        self.destination.mkdir()
        link = self.destination / "nested"
        link.symlink_to(outside)
        for flags in [(), ("-n",)]:
            self.assertEqual(self.run_ingest(*flags)[0], 1)
        self.assertEqual(list(outside.iterdir()), [])
        link.unlink()
        link.mkdir()
        (link / "a.jpg").symlink_to(outside / "missing")
        self.assertEqual(self.run_ingest()[0], 1)
        self.assertFalse((outside / "missing").exists())

    def test_symlink_cli_root_is_not_hidden_by_resolve(self):
        real = self.root / "real"
        real.mkdir()
        self.destination.symlink_to(real)
        self.assertEqual(self.run_ingest()[0], 2)

    def test_special_files_and_hardlinks_are_refused(self):
        fifo = self.source / "fifo"
        os.mkfifo(fifo)
        self.assertEqual(self.run_ingest()[0], 2)
        fifo.unlink()
        src = self.file("a.jpg")
        os.link(src, self.source / "hardlink")
        self.assertEqual(self.run_ingest()[0], 2)

    def test_permission_failure_preserves_staging_and_reports_failure(self):
        self.file("a.jpg")
        with patch.object(
            ingest, "normalize_path", side_effect=PermissionError("denied")
        ):
            code, out, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("denied", err)
        self.assertRegex(out, r"ingested:\s+0 files")
        self.assertTrue((self.source / "a.jpg").exists())

    def test_silent_chmod_failure_is_detected_before_staging_removal(self):
        self.file("a.jpg").chmod(0o600)
        real_chmod = Path.chmod

        def broken_chmod(path, mode, **kwargs):
            if path.name != "a.jpg":
                real_chmod(path, mode, **kwargs)

        with patch.object(Path, "chmod", broken_chmod):
            code, out, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("postcondition", err)
        self.assertTrue((self.source / "a.jpg").exists())
        self.assertFalse((self.destination / "a.jpg").exists())
        self.assertRegex(out, r"ingested:\s+0 files")

    def test_duplicate_failure_preserves_staging(self):
        self.file("a.jpg")
        self.file("a.jpg", archive=True)
        real_normalize = ingest.normalize_path

        def denied(path, **kwargs):
            if path.name == "a.jpg":
                raise PermissionError("duplicate denied")
            return real_normalize(path, **kwargs)

        with patch.object(ingest, "normalize_path", denied):
            code, out, _ = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertRegex(out, r"duplicates removed:\s+0 files")
        self.assertTrue((self.source / "a.jpg").exists())

    def test_silent_group_failure_is_detected(self):
        src = self.file("a.jpg")
        groups = [g for g in os.getgroups() if g != src.stat().st_gid]
        if not groups:
            self.skipTest("requires membership in a second group")
        self.group = grp.getgrgid(groups[0]).gr_name
        real_chown = ingest.shutil.chown

        def broken_chown(path, **kwargs):
            if path.is_dir():
                real_chown(path, **kwargs)

        with patch.object(ingest.shutil, "chown", broken_chown):
            code, out, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("does not have group", err)
        self.assertRegex(out, r"ingested:\s+0 files")
        self.assertTrue(src.exists())

    def test_directory_postcondition_failure_stops_before_move(self):
        self.file("a.jpg")
        self.destination.mkdir(mode=0o700)
        with patch.object(Path, "chmod", return_value=None):
            code, _, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("mode is not 2770", err)
        self.assertTrue((self.source / "a.jpg").exists())

    def test_overlapping_trees_are_rejected(self):
        for destination in [self.source, self.source / "nested", self.root]:
            self.destination = destination
            with (
                self.subTest(destination=destination),
                self.assertRaises(SystemExit) as result,
            ):
                self.run_ingest()
            self.assertEqual(result.exception.code, 2)

    def test_cross_device_copy_and_failure_cleanup(self):
        self.file("a.jpg")
        with patch.object(
            ingest.os, "link", side_effect=OSError(errno.EXDEV, "cross-device")
        ):
            code, _, err = self.run_ingest()
        self.assertEqual(code, 0, err)
        self.assert_modes(self.destination / "a.jpg")
        self.file("b.jpg")
        with (
            patch.object(
                ingest.os, "link", side_effect=OSError(errno.EXDEV, "cross-device")
            ),
            patch.object(
                ingest.shutil, "copyfileobj", side_effect=OSError("disk full")
            ),
        ):
            code, _, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("disk full", err)
        self.assertTrue((self.source / "b.jpg").exists())
        self.assertFalse((self.destination / "b.jpg").exists())

    def test_late_target_creation_never_overwrites(self):
        self.file("a.jpg")
        real_move = ingest.move_file

        def race(src, target, **kwargs):
            target.write_bytes(b"another writer")
            return real_move(src, target, **kwargs)

        with patch.object(ingest, "move_file", race):
            code, _, _ = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertEqual((self.destination / "a.jpg").read_bytes(), b"another writer")
        self.assertTrue((self.source / "a.jpg").exists())

    def test_staging_unlink_failure_retains_normalized_same_inode(self):
        src = self.file("a.jpg")
        src.chmod(0o600)
        before = src.stat()
        groups = [g for g in os.getgroups() if g != before.st_gid]
        if not groups:
            self.skipTest("requires membership in a second group")
        self.group = grp.getgrgid(groups[0]).gr_name
        target = self.destination / "a.jpg"
        real_unlink = Path.unlink

        def fail_staging_unlink(path, **kwargs):
            if path == src:
                # Normalization has already affected both names for this inode.
                self.assertEqual(src.stat().st_ino, target.stat().st_ino)
                self.assertEqual(src.stat().st_nlink, 2)
                self.assert_modes(src)
                self.assert_modes(target)
                raise PermissionError("staging unlink denied")
            return real_unlink(path, **kwargs)

        with patch.object(Path, "unlink", fail_staging_unlink):
            code, out, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("staging unlink denied", err)
        self.assertRegex(out, r"ingested:\s+0 files")
        self.assertRegex(out, r"failed:\s+1")
        self.assertFalse(target.exists())
        self.assertEqual(src.read_bytes(), b"incoming")
        self.assertEqual(src.stat().st_ino, before.st_ino)
        self.assertEqual(src.stat().st_nlink, 1)
        self.assert_modes(src)

    def test_final_postcondition_rechecks_earlier_output(self):
        self.file("a.jpg")
        self.file("b.jpg")
        real_move = ingest.move_file

        def change_earlier(src, target, **kwargs):
            real_move(src, target, **kwargs)
            if target.name == "b.jpg":
                (self.destination / "a.jpg").chmod(0o600)

        with patch.object(ingest, "move_file", change_earlier):
            code, _, err = self.run_ingest()
        self.assertEqual(code, 1)
        self.assertIn("postcondition", err)

    def test_discovery_failure_is_not_success(self):
        with patch.object(
            ingest.os, "walk", side_effect=PermissionError("unreadable subtree")
        ):
            code, _, err = self.run_ingest()
        self.assertEqual(code, 2)
        self.assertIn("unreadable subtree", err)

    def test_custom_modes_and_summary_only(self):
        self.file("a.jpg")
        code, out, err = self.run_ingest(
            "--file-mode", "0640", "--dir-mode", "2750", "--summary-only"
        )
        self.assertEqual(code, 0, err)
        self.assertEqual(
            stat.S_IMODE((self.destination / "a.jpg").stat().st_mode), 0o640
        )
        self.assertEqual(stat.S_IMODE(self.destination.stat().st_mode), 0o2750)
        self.assertNotIn("MOVE", out)
        self.assertIn("Summary", out)

    def test_unknown_group_fails_before_mutation_even_in_dry_run(self):
        self.file("a.jpg")
        code, _, err = self.run_ingest(
            "-n", "--group", "nonexistent-media-ingest-test-group"
        )
        self.assertEqual(code, 2)
        self.assertIn("ERROR", err)
        self.assertFalse(self.destination.exists())

    def test_help_and_argument_validation(self):
        for flags, expected in [
            (("--help",), 0),
            (("--verbose", "--summary-only"), 2),
            (("--file-mode", "888"), 2),
        ]:
            with self.subTest(flags=flags), self.assertRaises(SystemExit) as result:
                self.run_ingest(*flags)
            self.assertEqual(result.exception.code, expected)


if __name__ == "__main__":
    unittest.main()
