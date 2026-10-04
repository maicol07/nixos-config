# WSL and Windows dotfiles

The repository and its Nix configuration are the source of truth. Home Manager
manages the Linux home directory. `windows/default.nix` selects some of its
outputs and generates an immutable bundle and manifest. `sys` then materializes
regular files on the Windows filesystem. Windows files are never imported back
into the repository.

```text
flake / Home Manager modules / TOML sources
                   |
         evaluated Home Manager
            /              \
     Linux home       windows/default.nix
                              |
                      Nix store bundle
                              |
                automatic deployment after Home Manager
```

On WSL hosts, `nixos-rebuild switch` and `nixos-rebuild test` automatically
deploy Windows dotfiles after Home Manager. The `windows-dotfiles.service`
oneshot runs as the configured Linux user and uses the immutable bundle from
the generation being activated. It never evaluates the checkout or starts
another Nix build. A dedicated `windows-dotfiles.target` uses NixOS's
`X-StopOnReconfiguration` mechanism to run the service even on unchanged
switches, so rebuilding also repairs Windows drift. The mechanism is handled
by the [NixOS switch implementation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/sw/switch-to-configuration-ng/src/main.rs).

The service also runs when WSL starts. Builds, `dry-activate` and `sys check`
do not deploy Windows files. `nixos-rebuild boot` schedules the generation for
the next boot rather than deploying immediately. The deployment remains a
separate step from Home Manager, with no Syncthing or Windows links to WSL.
WinGet and DSC can manage Windows applications and system settings separately
in the future.

## Managed configurations

| Shared source | WSL | Windows |
|---|---|---|
| `home/programs/git.nix` and Home Manager integrations | `~/.config/git/config` | `%USERPROFILE%/.gitconfig` and `.gitconfig-include-0` |
| `home/shell/starship.toml`, through Home Manager | `~/.config/starship.toml` | `%USERPROFILE%/.config/starship.toml` |
| Minimal variant composed in `home/shell/fish.nix` | `~/.config/starship-minimal.toml` | `%USERPROFILE%/.config/starship-minimal.toml` |
| `home/programs/micro.nix` | `~/.config/micro/settings.json` | `%USERPROFILE%/.config/micro/settings.json` |
| `programs.lsd.settings` in `home/shell/fish.nix` | `~/.config/lsd/config.yaml` | `%APPDATA%/lsd/config.yaml` |
| `home/AGENTS.md`, through `home/programs/packages/personal/ai.nix` | `~/.codex/AGENTS.md` | `%USERPROFILE%/.codex/AGENTS.md` |
| The same `home/AGENTS.md` source | `~/.claude/CLAUDE.md` | `%USERPROFILE%/.claude/CLAUDE.md` |

Git reuses `programs.git.iniContent` and the declarative includes already
evaluated by Home Manager. Shared settings cover identities, public signing
keys, the conditional work identity, LF handling, branches, merges, delta,
LFS and GitHub helpers. The Windows transformation only replaces Linux commands
with `gh`, `delta`, `git-lfs`, `ssh.exe` and `op-ssh-sign.exe`, and generates
relative includes. The build fails if Linux runtime paths remain in the output.

The destinations follow the documentation for [Starship](https://starship.rs/config/),
[Micro](https://github.com/micro-editor/micro/blob/master/runtime/help/options.md)
and [lsd](https://github.com/lsd-rs/lsd). Existing Windows environment variables
such as `STARSHIP_CONFIG`, `MICRO_CONFIG_HOME` or `XDG_CONFIG_HOME` can change
where applications read their configuration. Deployment does not change those
variables.

Fish, its functions, abbreviations and plugins, direnv, broot, shell
integrations, 1Password/Node wrappers, service configurations
and other Home Manager files remain on the WSL/macOS side. Systemd units and
Windows Hello/PAM are specific to Linux/WSL. The current lazygit configuration
comes from Home Manager defaults, with no custom repository settings, and is
not exported.

AI instructions currently use `home/AGENTS.md` as their single source.
`home/programs/packages/personal/ai.nix` installs that content as
`~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md` on personal WSL/macOS hosts.
Both files are included in the Windows manifest and reuse those Home Manager
sources without duplicating their content. Edit `home/AGENTS.md` once to update
both applications on WSL/macOS and Windows.

No PowerShell profiles, Windows Terminal settings or other Windows-only
dotfiles have been added. The Windows-specific differences are the Git
commands and the `%APPDATA%` destination for lsd.

Private keys, tokens, credential databases, `gh` state, browser profiles and
1Password data are excluded. Git signing keys are public;
`keys/maicol07-pc-wsl-hello.pem` is also public and is not exported.
The manifest is a file allowlist, with no recursive home directory copying.

## Commands

After a WSL rebuild, `sys` is available in PATH. Before that rebuild:

```bash
nix run .#sys -- check
nix run .#sys -- apply-windows
```

The usual workflow:

```bash
$EDITOR home/programs/git.nix
sys check
sys apply
```

| Command | Effect |
|---|---|
| `sys apply-wsl` | `sudo nixos-rebuild switch`, including Home Manager and automatic Windows deployment |
| `sys apply-windows` | Build the bundle and deploy Windows files, without rebuilding WSL |
| `sys apply` | The same rebuild as `apply-wsl`; the service deploys Windows without a second deploy |
| `sys check` | Check the flake, evaluate the selected system, build the bundle and compare Windows files |

`check` does not change the repository, lockfile, active system or Windows
files. Nix may download inputs and build outputs in its store. It reports
`DRIFT: <file>` even when the full flake check fails.
Exit codes: `0` up to date, `1` drift, `2` configuration or deployment error.

Because Windows deployment is automatic on every WSL switch, `apply-wsl` now
also updates Windows. Use `apply-windows` to update only Windows without a
rebuild. To inspect automatic deployment logs:

```bash
systemctl status windows-dotfiles.service
journalctl -u windows-dotfiles.service -b
```

The default directory is `NH_OS_FLAKE`, or `~/.config/nixos` if it is unset.
The default host is the machine hostname. Explicit overrides are available:

```bash
sys check --flake /path/to/repository --host maicol07-galaxy
```

`SYS_FLAKE` and `SYS_HOST` provide the same overrides. PowerShell queries the
Windows profile, AppData and LocalAppData without loading the personal profile,
then `wslpath` converts the paths. The PowerShell executable path follows the
automount root of the evaluated WSL system. For manual commands, set
`SYS_POWERSHELL` and `SYS_WSLPATH` if different executable paths are needed.
The automatic service uses the paths configured in
`modules/wsl-windows-dotfiles.nix`, independently of the interactive shell.

As with other flake commands in this repository, new source files must be
visible to Git. `git add -N path` makes them visible without staging their
contents or committing. Runtime output stays outside the repository; builds
use `--no-link` and do not create `result`.

## Editing and adding dotfiles

Edit the Home Manager module or TOML source listed in the table. Both targets
derive from that source, even before WSL has been rebuilt. Do not edit the
Windows copies.

To add a shared file, first manage it with Home Manager, then add an entry to
the `files` list in `windows/default.nix`:

```nix
(shared "appdata" "tool/config.json" home.xdg.configFile."tool/config.json".source)
```

The allowed roots are `userprofile`, `appdata` and `localappdata`; the target
path is relative to its root. For platform differences, generate the Windows
variant from the same evaluated settings and apply only the required overrides.
Do not add files containing credentials. Update the bundle test when the list
of exported files changes.

## Updates and limitations

Deployment compares bytes before writing and prints `CREATED`, `UPDATED` or
`UNCHANGED`. Identical files retain their contents and timestamps. A manual
Windows edit is reported by the check and replaced by the next deployment.

Deployment validates the entire manifest, reads expected contents and checks
destinations before writing. It rejects path traversal, duplicate targets and
symlinks in parent directories. An existing symlink at the final file path is
reported as drift and replaced with a regular file, including dangling links
and links whose contents already match. The referenced file is never modified.
It stages all temporary files in the destination
directories before replacing the targets with renames. Existing POSIX modes
are retained, and new files use `0644`; DrvFS applies its own permission and
ACL rules. Custom Windows ACLs are not preserved. Temporary files are removed
after handled errors.

A failed Home Manager service prevents automatic Windows deployment. A Windows
deployment failure fails the service and is reported by the rebuild. Linux may
already be updated at that point; there is no rollback across both filesystems.
Correct the error and run `sys apply-windows` or repeat the rebuild.

Atomicity is per file, not for the entire bundle. A rename failure can leave
some files updated; the command fails explicitly, and another run completes
deployment. Forced termination can leave `.sys-*` temporary files on Windows.
Deployment does not remove old targets deleted from the manifest or coordinate
concurrent runs.

The first deployment takes ownership of the full contents of the files in the
table. Move any existing settings you want to keep into the Nix source, or
back them up before deployment. Files outside the manifest are untouched.

Windows applications must already be installed, and Git helper commands must
be available in the Windows PATH. The `op-ssh-sign.exe` alias requires
1Password configured for [SSH signing](https://www.1password.dev/ssh/git-commit-signing).
Deployment does not install applications, Micro plugins, LSP servers, fonts or
Starship initialization hooks in the Windows shell.

## Verification

```bash
nix build --no-link .#checks.x86_64-linux.windows-dotfiles
nix build --no-link .#windows-dotfiles-maicol07-pc
nix build --no-link .#windows-dotfiles-maicol07-galaxy
nix build --no-link .#sys
nix flake check --no-write-lock-file
```

The dedicated check tests file creation, drift, idempotence, permissions,
unsafe manifests, preflight failures, error cleanup, bundle contents, Git
parsing and conditional includes. It also verifies that a failed rebuild
prevents deployment and that the check still reports drift after a Nix error.
The activation entrypoint is tested for deployment, idempotence and failure
propagation. The CLI tests verify that rebuild commands do not deploy twice.

Global validation can fail because of unrelated host configurations. With the
current lockfile, the server still uses `services.journald.extraConfig`, which
nixpkgs has removed. It needs migration to `services.journald.settings.Journal`.
This issue predates Windows deployment and remains outside this change.
