"""Exercise generated content and deployment against isolated user profiles."""

import contextlib
import io
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, os.environ.get("SYS_SCRIPTS", str(Path(__file__).resolve().parents[1] / "scripts")))
import windows_deploy as deploy

spec = importlib.util.spec_from_file_location("sys_cli", Path(deploy.__file__).with_name("sys.py"))
assert spec is not None and spec.loader is not None
cli = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cli)


class DeploymentTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="sys-test-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.bundle = self.directory / "bundle"
        self.bundle.mkdir()
        (self.bundle / "expected").write_bytes("shared café\n".encode())
        self.roots = {name: self.directory / name for name in ("userprofile", "appdata", "localappdata")}
        for root in self.roots.values():
            root.mkdir()
        self.entry = {"root": "userprofile", "target": ".config/tool/settings", "source": "expected"}
        self.manifest([self.entry])

    def manifest(self, entries: list[dict[str, str]]) -> None:
        (self.bundle / "manifest.json").write_text(json.dumps(entries))

    def test_check_apply_idempotence_and_drift(self) -> None:
        target = self.roots["userprofile"] / self.entry["target"]
        files = deploy.plan(self.bundle, self.roots)
        self.assertEqual(deploy.check(files), 1)
        self.assertFalse(target.parent.exists())
        deploy.apply(files)
        before = target.stat().st_mtime_ns
        self.assertEqual(target.read_bytes(), (self.bundle / "expected").read_bytes())
        deploy.apply(deploy.plan(self.bundle, self.roots))
        self.assertEqual(target.stat().st_mtime_ns, before)
        target.write_bytes(b"manual drift")
        target.chmod(0o640)
        self.assertEqual(deploy.check(deploy.plan(self.bundle, self.roots)), 1)
        self.assertEqual(target.read_bytes(), b"manual drift")
        deploy.apply(deploy.plan(self.bundle, self.roots))
        self.assertEqual(target.stat().st_mode & 0o777, 0o640)
        self.assertEqual(deploy.check(deploy.plan(self.bundle, self.roots)), 0)
        self.assertEqual(list(target.parent.glob(".sys-*")), [])

    def test_reject_unsafe_manifest_and_symlinks(self) -> None:
        for target in ("../outside", "/absolute", "C:/outside", "a/../b", "a\\b", "a//b", "a/./b"):
            with self.subTest(target=target):
                self.manifest([self.entry | {"target": target}])
                with self.assertRaises(ValueError):
                    deploy.plan(self.bundle, self.roots)
        self.manifest([self.entry, self.entry])
        with self.assertRaises(ValueError):
            deploy.plan(self.bundle, self.roots)
        self.manifest([self.entry])
        (self.roots["userprofile"] / ".config").symlink_to(self.roots["appdata"], target_is_directory=True)
        with self.assertRaises(ValueError):
            deploy.plan(self.bundle, self.roots)

    def test_preflight_failure_leaves_targets_untouched(self) -> None:
        self.manifest([self.entry, self.entry | {"target": "other", "source": "missing"}])
        with self.assertRaises(FileNotFoundError):
            deploy.plan(self.bundle, self.roots)
        self.assertFalse((self.roots["userprofile"] / ".config").exists())

    def test_leaf_symlinks_are_replaced_without_modifying_their_referents(self) -> None:
        original = self.directory / "original"
        content = (self.bundle / "expected").read_bytes()
        original.write_bytes(content)
        target = self.roots["userprofile"] / self.entry["target"]
        target.parent.mkdir(parents=True)
        for referent in (original, self.directory / "missing"):
            with self.subTest(referent=referent):
                target.symlink_to(referent)
                files = deploy.plan(self.bundle, self.roots)
                self.assertEqual(len(files), 1)
                self.assertEqual(deploy.check(files), 1)
                self.assertTrue(target.is_symlink())
                deploy.apply(files)
                self.assertFalse(target.is_symlink())
                self.assertEqual(target.read_bytes(), content)
                self.assertEqual(original.read_bytes(), content)
                self.assertFalse((self.directory / "missing").exists())
                self.assertEqual(deploy.check(deploy.plan(self.bundle, self.roots)), 0)
                target.unlink()

    def test_stage_and_replace_failures_cleanup(self) -> None:
        files = deploy.plan(self.bundle, self.roots)
        target = files[0].target
        for operation in ("fsync", "replace"):
            with self.subTest(operation=operation), patch.object(deploy.os, operation, side_effect=OSError("test failure")):
                with self.assertRaises(OSError):
                    deploy.apply(files)
                self.assertFalse(target.exists())
                self.assertEqual(list(target.parent.glob(".sys-*")), [])

    def test_generated_bundle_and_git_includes(self) -> None:
        bundle_path = os.environ.get("WINDOWS_DOTFILES")
        if not bundle_path:
            self.skipTest("WINDOWS_DOTFILES was not provided")
        bundle = Path(bundle_path)
        files = deploy.plan(bundle, self.roots)
        self.assertEqual(len(files), 8)
        for file in files:
            self.assertNotIn(b"/nix/store/", file.content)
            self.assertNotIn(b"/mnt/c/", file.content)
            self.assertNotIn(b"PRIVATE KEY", file.content)
        deploy.apply(files)
        instructions = Path(os.environ["AI_INSTRUCTIONS"]).read_bytes()
        for name in (".codex/AGENTS.md", ".claude/CLAUDE.md"):
            self.assertEqual((self.roots["userprofile"] / name).read_bytes(), instructions)
        timestamps = {file.target: file.target.stat().st_mtime_ns for file in files}
        deploy.apply(deploy.plan(bundle, self.roots))
        self.assertEqual({target: target.stat().st_mtime_ns for target in timestamps}, timestamps)
        self.assertEqual(deploy.check(deploy.plan(bundle, self.roots)), 0)
        config = self.roots["userprofile"] / ".gitconfig"
        arguments = ["git", "config", "--file", str(config), "--includes"]
        name = subprocess.check_output(arguments + ["--get", "user.name"], text=True).strip()
        self.assertEqual(name, "Maicol Battistini")
        email = subprocess.check_output(arguments + ["--list"], text=True)
        self.assertIn("gpg.ssh.program=op-ssh-sign.exe", email)
        self.assertIn("filter.lfs.process=git-lfs filter-process", email)
        repository = self.directory / "repository"
        subprocess.run(["git", "init", "--quiet", str(repository)], check=True)
        subprocess.run(["git", "-C", str(repository), "remote", "add", "origin", "git@gitlab.trust-itservices.com:team/project.git"], check=True)
        environment = os.environ | {"GIT_CONFIG_GLOBAL": str(config), "GIT_CONFIG_NOSYSTEM": "1"}
        result = subprocess.check_output(["git", "-C", str(repository), "config", "user.email"], env=environment, text=True)
        self.assertEqual(result.strip(), "m.battistini@trust-itservices.com")

    def test_cli_rebuild_failure_prevents_windows_deployment(self) -> None:
        settings = json.dumps({"isWsl": True, "powershell": "/test/powershell.exe"})
        with patch.object(sys, "argv", ["sys", "apply", "--flake", str(self.directory)]), \
             patch.object(cli.subprocess, "check_output", return_value=settings), \
             patch.object(cli.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "rebuild")), \
             patch.object(deploy, "windows_roots") as roots:
            with self.assertRaises(subprocess.CalledProcessError):
                cli.main()
            roots.assert_not_called()

    def test_cli_rebuild_commands_do_not_repeat_automatic_deployment(self) -> None:
        settings = json.dumps({"isWsl": True, "powershell": "/test/powershell.exe"})
        for command in ("apply", "apply-wsl"):
            with self.subTest(command=command), \
                 patch.object(sys, "argv", ["sys", command, "--flake", str(self.directory)]), \
                 patch.object(cli.subprocess, "check_output", return_value=settings), \
                 patch.object(cli.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as rebuild, \
                 patch.object(deploy, "windows_roots") as roots:
                self.assertEqual(cli.main(), 0)
                self.assertEqual(rebuild.call_count, 1)
                self.assertEqual(rebuild.call_args.args[0][:3], ["sudo", "nixos-rebuild", "switch"])
                roots.assert_not_called()

    def test_activation_entrypoint_deploys_and_propagates_failures(self) -> None:
        powershell = self.directory / "powershell"
        powershell.write_text(f"#!{sys.executable}\nprint('{{\"userprofile\":\"C:/Users/Test\",\"appdata\":\"C:/AppData\",\"localappdata\":\"C:/LocalAppData\"}}')\n")
        powershell.chmod(0o755)
        wslpath = self.directory / "wslpath"
        mapping = {"C:/Users/Test": str(self.roots["userprofile"]), "C:/AppData": str(self.roots["appdata"]), "C:/LocalAppData": str(self.roots["localappdata"])}
        wslpath.write_text(f"#!{sys.executable}\nimport sys\nprint({mapping!r}[sys.argv[2]])\n")
        wslpath.chmod(0o755)
        environment = os.environ | {"SYS_POWERSHELL": str(powershell), "SYS_WSLPATH": str(wslpath), "PYTHONDONTWRITEBYTECODE": "1"}
        command = [sys.executable, str(Path(deploy.__file__)), str(self.bundle)]
        first = subprocess.run(command, env=environment, capture_output=True, text=True)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertIn("CREATED:", first.stdout)
        target = self.roots["userprofile"] / self.entry["target"]
        timestamp = target.stat().st_mtime_ns
        second = subprocess.run(command, env=environment, capture_output=True, text=True)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("UNCHANGED:", second.stdout)
        self.assertEqual(target.stat().st_mtime_ns, timestamp)
        environment["SYS_POWERSHELL"] = str(self.directory / "missing-powershell")
        failed = subprocess.run(command, env=environment, capture_output=True, text=True)
        self.assertEqual(failed.returncode, 2)
        self.assertIn("FAILED:", failed.stderr)
        self.assertEqual(target.stat().st_mtime_ns, timestamp)

    def test_cli_check_reports_drift_after_nix_check_failure(self) -> None:
        settings = json.dumps({"isWsl": True, "powershell": "/test/powershell.exe"})
        with patch.object(sys, "argv", ["sys", "check", "--flake", str(self.directory)]), \
             patch.object(cli.subprocess, "check_output", side_effect=[settings, str(self.bundle)]), \
             patch.object(cli.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)), \
             patch.object(deploy, "windows_roots", return_value=self.roots), \
             patch.object(deploy, "apply") as apply, contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(cli.main(), 2)
            apply.assert_not_called()
            self.assertFalse((self.roots["userprofile"] / ".config").exists())


if __name__ == "__main__":
    with contextlib.redirect_stdout(io.StringIO()):
        unittest.main()
