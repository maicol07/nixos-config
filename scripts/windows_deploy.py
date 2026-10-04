"""Materialize an explicit Nix-generated allowlist on Windows, never sync back."""

import argparse
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import shutil
import stat
import subprocess
import sys
import tempfile
from dataclasses import dataclass


@dataclass(frozen=True)
class ManagedFile:
    target: Path
    content: bytes
    mode: int
    exists: bool


def windows_roots() -> dict[str, Path]:
    powershell = os.environ.get("SYS_POWERSHELL") or shutil.which("powershell.exe")
    if not powershell:
        powershell = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    command = """
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
@{
  userprofile = [Environment]::GetFolderPath('UserProfile')
  appdata = [Environment]::GetFolderPath('ApplicationData')
  localappdata = [Environment]::GetFolderPath('LocalApplicationData')
} | ConvertTo-Json -Compress
"""
    output = subprocess.run(
        [powershell, "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", command],
        check=True, capture_output=True, encoding="utf-8-sig", timeout=30,
    ).stdout
    values = json.loads(output)
    if not isinstance(values, dict):
        raise ValueError("PowerShell did not return Windows profile paths")
    roots: dict[str, Path] = {}
    for name in ("userprofile", "appdata", "localappdata"):
        value = values.get(name)
        if not isinstance(value, str) or not PureWindowsPath(value).is_absolute() or value.startswith("\\\\"):
            raise ValueError(f"Invalid Windows {name} path")
        converted = subprocess.run(
            [os.environ.get("SYS_WSLPATH", "/sbin/wslpath"), "-u", value],
            check=True, capture_output=True, encoding="utf-8", timeout=10,
        ).stdout.strip()
        root = Path(converted)
        if not root.is_absolute() or not root.is_dir():
            raise ValueError(f"Windows {name} is not mounted: {root}")
        roots[name] = root.resolve()
    return roots


def relative_path(value: object) -> PurePosixPath:
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        raise ValueError("Manifest paths must be nonempty relative POSIX paths")
    path = PurePosixPath(value)
    if path.is_absolute() or any(part in ("", ".", "..") for part in value.split("/")):
        raise ValueError(f"Unsafe manifest path: {value}")
    return path


def plan(bundle: Path, roots: dict[str, Path]) -> list[ManagedFile]:
    entries = json.loads((bundle / "manifest.json").read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        raise ValueError("Manifest must contain a nonempty file allowlist")
    files: list[ManagedFile] = []
    targets: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {"root", "target", "source"}:
            raise ValueError("Invalid manifest entry")
        root_name = entry["root"]
        if not isinstance(root_name, str) or root_name not in roots:
            raise ValueError("Unknown Windows root in manifest")
        root = roots[root_name]
        target = root / relative_path(entry["target"])
        source = bundle / relative_path(entry["source"])
        if not source.resolve().is_relative_to(bundle.resolve()):
            raise ValueError("Manifest source escapes the generated bundle")
        key = str(target).casefold()
        if key in targets:
            raise ValueError(f"Duplicate Windows target: {target}")
        targets.add(key)
        linked = target.is_symlink()
        for path in (target, *target.parents):
            if path == root:
                break
            if path.is_symlink():
                if path == target:
                    continue
                raise ValueError(f"Refusing a symlink in Windows target: {path}")
            if path.exists() and (not path.is_file() if path == target else not path.is_dir()):
                raise ValueError(f"Invalid Windows target type: {path}")
        if not target.parent.resolve().is_relative_to(root.resolve()):
            raise ValueError(f"Windows target escapes its root: {target}")
        content = source.read_bytes()
        exists = linked or target.exists()
        mode = stat.S_IMODE(target.stat().st_mode) if exists and not linked else 0o644
        if exists and not linked and target.read_bytes() == content:
            print(f"UNCHANGED: {target}")
        else:
            files.append(ManagedFile(target, content, mode, exists))
    return files


def check(files: list[ManagedFile]) -> int:
    for file in files:
        print(f"DRIFT: {file.target}")
    return 1 if files else 0


def apply(files: list[ManagedFile]) -> None:
    staged: list[tuple[ManagedFile, Path]] = []
    try:
        # Stage every changed file before replacing any destination.
        for file in files:
            file.target.parent.mkdir(parents=True, exist_ok=True)
            descriptor, name = tempfile.mkstemp(prefix=".sys-", dir=file.target.parent)
            temporary = Path(name)
            staged.append((file, temporary))
            with os.fdopen(descriptor, "wb") as stream:
                stream.write(file.content)
                stream.flush()
                os.fsync(stream.fileno())
            temporary.chmod(file.mode)
        for file, temporary in staged:
            os.replace(temporary, file.target)
            print(f"{'UPDATED' if file.exists else 'CREATED'}: {file.target}")
    finally:
        for _, temporary in staged:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    arguments = parser.parse_args()
    try:
        apply(plan(arguments.bundle, windows_roots()))
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(2)
