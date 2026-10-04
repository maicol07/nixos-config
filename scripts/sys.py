"""Rebuild WSL with automatic Windows deployment, or deploy Windows separately."""

import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import sys

import windows_deploy


def run(arguments: list[str]) -> None:
    subprocess.run(arguments, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("apply-wsl", "apply-windows", "apply", "check"))
    parser.add_argument("--flake", default=os.environ.get("SYS_FLAKE", os.environ.get("NH_OS_FLAKE", str(Path.home() / ".config/nixos"))))
    parser.add_argument("--host", default=os.environ.get("SYS_HOST", socket.gethostname()))
    args = parser.parse_args()
    if not args.host or any(character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for character in args.host):
        raise ValueError("Invalid host name")
    repository = Path(args.flake).expanduser().resolve(strict=True)
    flake = str(repository)
    configuration = f"{flake}#nixosConfigurations.{args.host}"
    settings = json.loads(subprocess.check_output(
        ["nix", "eval", "--json", "--no-write-lock-file", f"{configuration}.config", "--apply",
         'c: { isWsl = c.wsl.enable; powershell = c.wsl.wslConf.automount.root + "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"; }'], text=True,
    ))
    if not isinstance(settings, dict) or settings.get("isWsl") is not True:
        raise ValueError("sys requires a WSL NixOS host")
    powershell = settings.get("powershell")
    if not isinstance(powershell, str):
        raise ValueError("Invalid WSL PowerShell path")
    os.environ.setdefault("SYS_POWERSHELL", powershell)
    result = 0
    if args.command == "check":
        for arguments in (
            ["nix", "flake", "check", "--no-write-lock-file", flake],
            ["nix", "eval", "--raw", "--no-write-lock-file", f"{configuration}.config.system.build.toplevel.drvPath"],
        ):
            if subprocess.run(arguments).returncode != 0:
                print(f"FAILED: {' '.join(arguments)}", file=sys.stderr)
                result = 2
        print()
    if args.command in ("apply-wsl", "apply"):
        run(["sudo", "nixos-rebuild", "switch", "--flake", f"{flake}#{args.host}", "--no-write-lock-file"])
    if args.command in ("apply-windows", "check"):
        roots = windows_deploy.windows_roots()
        output = subprocess.check_output(
            ["nix", "build", "--no-link", "--print-out-paths", "--no-write-lock-file",
             f"{flake}#windows-dotfiles-{args.host}"], text=True,
        ).strip()
        files = windows_deploy.plan(Path(output), roots)
        if args.command == "check":
            return max(result, windows_deploy.check(files))
        windows_deploy.apply(files)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(2)
