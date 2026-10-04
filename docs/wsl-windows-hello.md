# Windows Hello for sudo on WSL

`wsl.nix` imports `modules/wsl-windows-hello.nix` and enables
`wsl.windowsHello` on both WSL hosts. Only the `sudo` PAM service gains a
Windows Hello rule. Other PAM services, the server and macOS are unaffected.

The existing package overlay also pins `rxvt-unicode-unwrapped` to C++17, with
the user's approval. GCC 16's C++20 default exposes a conflict between its
`std::lerp` and rxvt's helper, preventing the complete WSL system build. The
standalone package build passed with `CXXFLAGS = "-O2 -std=gnu++17"`.
The same compiler also exposes Contour's selection of the C++26 `<simd>` header
in a C++23 build. A guarded header check retains its supported experimental SIMD
implementation. Both compatibility adjustments live in the existing overlay.

## Sources and alternatives

Research on 2026-10-04 found no suitable package in the pinned nixpkgs tree,
existing overlays or the pinned NixOS-WSL modules. Web searches included Nix,
NixOS, flakes, overlays, modules, dotfiles, GitLab and Codeberg. GitHub repository
and issue searches found these relevant implementations:

| Source | Assessment |
| --- | --- |
| [lzlrd/wsl-hello-sudo](https://github.com/lzlrd/wsl-hello-sudo) | Selected. Recent source fixes and Windows ARM64 CI work, although the available v3.0.0 binary release remains x64. Latest source commit dated 2026-03-01; repository push dated 2026-05-28. |
| [nullpo-head/WSL-Hello-sudo](https://github.com/nullpo-head/WSL-Hello-sudo) | Original v2.0.0, last repository push 2023-05-21. Older than the selected fork. |
| [evanphilip/WSL-Hello-sudo](https://github.com/evanphilip/WSL-Hello-sudo) | v2.1.1, last repository push 2024-09-06. Older source and release. |
| [NixOS-WSL PR #83](https://github.com/nix-community/NixOS-WSL/pull/83) | Closed without merge. Starts a different Windows verifier through `pam_exec`, trusts its exit status and uses obsolete Nix configuration. Its author links security limitations. Rejected. |
| [nokazn/dotfiles](https://github.com/nokazn/dotfiles) | Imperative setup and manual PAM edits, not a reusable declarative NixOS integration. |
| [AngraNET guide](https://github.com/AngraNET/wsl-hello-sudo-guide) | Upstream build guide, not Nix packaging. |

No third-party Nix code was copied. GitHub Code Search returned HTTP 401 without
authentication; grep.app returned HTTP 429; Codeberg blocked the web crawler.
The searches do not prove that no other implementation exists.

The root flake input is `nixpkgs_2` in `flake.lock`, revision
`a7868a727837f3c09cee2ce0ca671c76b1589fed`, NixOS 26.11 unstable. The other
`nixpkgs` lock node belongs to another dependency and is not the system package set.
The actual pinned `nixos/modules/security/pam.nix` supports `rules.auth`,
`modulePath`, `control` and order relative to another rule.

## Packaging and security model

`pkgs/wsl-hello-sudo/default.nix` compiles the upstream Rust PAM module at
`3255c5244edf9ed337e79732539c9077207d3058`. Source and Cargo dependencies have
explicit hashes. It links nixpkgs OpenSSL and PAM, without upstream installers or
vendored OpenSSL. The build output is renamed from `libpam_wsl_hello.so` to
`$out/lib/security/pam_wsl_hello.so`. A small substitution turns a verifier
initialization panic into an authentication error. Old generated bindgen layout
tests dereference null pointers and are rejected by current Rust; they are
disabled in favor of the isolated integration test.
The challenge file is unlinked immediately after opening; its descriptor remains
available to Windows, and configuration or launch errors leave no temporary file.

The separate `bridge` derivation extracts only `WindowsHelloBridge.exe` from
[upstream v3.0.0](https://github.com/lzlrd/wsl-hello-sudo/releases/tag/v3.0.0),
published 2025-03-22, with an explicit archive SHA-256. This Windows binary is
not built reproducibly from source here. Its provenance is the upstream release,
not a signed or independently attested build. An asset replacement fails the
pinned hash. Linux builds do not need a Windows Rust toolchain.

Upstream generates `pam_wsl_hello:<Linux username>:<random UUID>`, passes it to the
bridge and verifies the returned signature with OpenSSL SHA-256 against the
enrolled public key. The bridge calls Windows `KeyCredentialManager`, opens the
credential named `pam_wsl_hello_<Linux username>` under the current Windows user
and requests a signature after Windows Hello verification. The private key stays
in the Windows credential provider; Linux receives only its public PEM key.
Upstream describes TPM-backed keys, but this integration does not check hardware
attestation and cannot guarantee TPM storage on every host.

A bridge returning success or random bytes cannot authenticate without a valid
signature. The key name and fresh challenge prevent using an unrelated key or
replaying an old response. Another Windows process may request use of the same
credential: security depends on Windows enforcing Hello consent and the user
recognizing a legitimate prompt. There is no binding of the displayed prompt to
the exact sudo command, executable attestation, or protection against a compromised
Windows account. Windows administrators can launch WSL as root. Windows is part
of the trusted host, not an adversary isolated by WSL.

The public key is embedded in the Nix store and exposed through a root-owned
`/etc` symlink. Bootstrap cannot change the key accepted by the active generation.
The Windows executable lives under the Windows user's LocalAppData and is writable
by that user; replacing it still cannot bypass signature verification, but can
cause denial of service or deceptive prompts. This repository also already grants
the configured Linux user Nix daemon trust, which is effectively root access.

## Enrollment and activation

First keep a root shell open, for example `sudo -i`, or open one from Windows with
`wsl.exe -d NixOS -u root`. Ensure the normal Linux password works. The WSL module
changes the existing passwordless wheel policy to require authentication. This
does not change the server's policy.

Check `sudo passwd -S maicol07` first. Status `L` means the account is locked and
password fallback cannot work. Set a Linux password interactively with
`sudo passwd maicol07` before activation; never put that password in Nix or Git.
The repository uses mutable user accounts, so normal password changes persist.

From this repository, before switching the system:

```bash
nix build --out-link /tmp/wsl-windows-hello path:.#nixosConfigurations.maicol07-pc.config.system.build.wslWindowsHello
/tmp/wsl-windows-hello/bin/wsl-hello-bootstrap "$PWD/keys/$(hostname)-wsl-hello.pem"
```

Use `maicol07-galaxy` instead for that host. Run bootstrap as the configured Linux
user, without sudo. It detects LocalAppData using Windows PowerShell, converts
the path using `/sbin/wslpath`, installs the bridge under
`%LOCALAPPDATA%\Programs\wsl-hello-sudo`, invokes upstream `creator`, validates
the exported PEM and copies only the public key to the requested repository path.
Existing identical bridge/key files are retained; differing files are rejected.
Upstream reuses an existing credential. No PAM files are modified by bootstrap.

The Windows username may differ from the Linux username. No Windows username is
configured: Windows interop runs under the Windows user launching WSL, while the
Linux username selects the credential name. Each physical host enrolls its own
key; `wsl.nix` selects `keys/<hostname>-wsl-hello.pem` when present. Missing keys
leave password fallback available. Do not export or commit private keys.

Review the public key, then build and activate:

```bash
nixos-rebuild build --flake "path:$PWD#$(hostname)"
sudo nixos-rebuild test --flake "path:$PWD#$(hostname)"
sudo -k
sudo true
```

Repeat `sudo -k; sudo true`, cancel Hello and supply the Linux password. Repeat
from a fresh terminal. Test Windows Terminal, the IDE terminal and SSH. After
these pass, run `sudo nixos-rebuild switch --flake "path:$PWD#$(hostname)"`.
`build` never activates anything; `test` changes the running generation without
making it the boot default. Keep the root shell through all these checks.

`path:` includes new untracked module and public-key files. A normal Git-backed
flake omits untracked files; add reviewed files to Git before using `--flake .`.
Staging is not required for the commands above.

## Authentication and failure handling

The evaluated authentication stack is:

```text
auth sufficient <wsl-hello-sudo>/lib/security/pam_wsl_hello.so  # order 11690
auth sufficient <linux-pam>/lib/security/pam_unix.so likeauth try_first_pass  # order 11700
auth required <linux-pam>/lib/security/pam_deny.so  # order 12500
```

The Windows Hello rule uses `unix.order - 10`, not a fixed order. Successful
signature verification skips password authentication; any recoverable Hello
failure falls through to `pam_unix`. Account and session checks still run.
No password, session or other service rules are replaced. No new `NOPASSWD` rule
is introduced for WSL. Sudo's normal credential cache still applies; use `sudo -k`
for every authentication test.

The launcher uses absolute PowerShell and wslpath paths, so the existing
`appendWindowsPath = false` works. Sudo preserves `WSL_INTEROP` and SSH markers.
It never guesses another session's interop socket. SSH markers, a missing socket
or disabled binfmt interop cause immediate fallback. A valid session socket is
still needed with systemd and IDE terminals; absent or stale sockets fail rather
than waiting indefinitely.

PowerShell path discovery has a 5-second deadline; bridge authentication has a
30-second deadline, each with a 2-second forced-kill grace. Windows output goes
to temporary files, so a lingering Windows child cannot hold PAM's stdout pipe
open. Maximum nominal wait is 39 seconds across both phases. Timeout bounds the
Linux authentication wait; WSL may leave a Windows process or dialog alive until
Windows completes it. Dismiss a remaining dialog. This integration does not claim
to forcibly terminate every host-side UI process.

Path discovery reads from `/dev/null`, preserving the original challenge stdin
for the bridge. This matters on the real host: Windows PowerShell otherwise
consumes that input and the bridge signs different bytes.

## Disable, recover and update

Set `wsl.windowsHello.enable = false` in `wsl.nix` and rebuild to restore the
previous WSL policy. That previous policy is passwordless wheel sudo. To retain
password authentication while disabling Hello, also set
`security.sudo.wheelNeedsPassword = lib.mkForce true` in the WSL configuration.
Disabling the module does not delete Windows credentials or the bridge.

If sudo stops working, use the retained root shell or Windows
`wsl.exe -d NixOS -u root`, then run `nixos-rebuild switch --rollback`. Restore a
known good generation before closing the recovery shell. Do not edit
`/etc/pam.d` or copy modules into `/lib/security`.

To update upstream, review Linux and Windows source changes separately, update
the pinned revision/source hash/Cargo hash and release URL/hash, rebuild, then
rerun the isolated test. Back up a differing installed Windows bridge before
running bootstrap again. Preserve the enrolled public key unless deliberately
rotating credentials. A Windows Hello reset or changed Windows account requires
enrollment and review of a replacement public key.

## Verification

The repeatable integration test requires root in a private mount namespace and
the pinned Python/OpenSSL toolchain. It uses an isolated shadow file with a random
test password, the compiled upstream PAM module, actual `pam_unix`, signed
challenges and controlled bridge failures. It never authenticates against or
edits the active system's shadow or PAM configuration.

```bash
integration=$(nix build --no-link --print-out-paths path:.#nixosConfigurations.maicol07-pc.config.system.build.wslWindowsHello)
pam=$(nix eval --raw path:.#nixosConfigurations.maicol07-pc.pkgs.pam.outPath)
nix shell --impure --expr 'let f = builtins.getFlake ("path:" + toString ./.); p = f.nixosConfigurations.maicol07-pc.pkgs; in [ p.python3 p.openssl ]' --command bash -c 'exec sudo env PATH="$PATH" unshare --mount --propagation private python3 tests/wsl-windows-hello.py "$1" "$2"' bash "$integration" "$pam"
```

Results on 2026-10-04:

| Check | Result |
| --- | --- |
| Linux package, Windows bridge extraction and shell applications | Build passed; shell application builds also run ShellCheck. |
| NixOS `maicol07-pc` full system build | Passed after the GCC 16 compatibility fixes and the rename to `wsl.windowsHello`. |
| Root `switch-to-configuration dry-activate` | Passed; it would restart systemd, Home Manager and several system services as part of the existing pinned system upgrade. No active generation was changed. |
| NixOS `maicol07-galaxy` evaluation | Passed; no failed assertions. It needs its own enrollment and Linux password before deployment. |
| PAM order and generated public-key source | Verified against the actual pinned modules; the real public key resolves to a Nix store file. |
| Other PAM services | Every service except `sudo` compares byte-for-byte equal with this module disabled on both WSL hosts, including `su`. |
| Windows interop and absolute PowerShell path | Executed successfully on the actual WSL2 host with systemd and Windows PATH disabled. |
| Real enrollment | Completed. Public key exported to `keys/maicol07-pc-wsl-hello.pem`; second bootstrap invocation succeeded with the same key. |
| Real Windows Hello signature | `openssl dgst -sha256 -verify` returned `Verified OK` after isolating PowerShell's stdin. |
| Real Windows process timeout | A Windows PowerShell `Start-Sleep` process returned timeout status 124 after 2 seconds in a targeted timeout test. |
| Isolated PAM integration | 21 checks passed: valid and invalid signatures, cancellation/failure/unsupported/unconfigured exit statuses, missing/non-executable bridges, missing/invalid keys and config, SSH, missing/disabled interop, launcher output preservation, 30-second timeout and incorrect Linux password rejection. Synthetic failure statuses do not claim the corresponding Windows UI was tested. |
| `nix flake check --no-build` | Blocked by the pre-existing server assertion for `services.journald.extraConfig`; not changed by this task. |
| Diff whitespace and new Nix file formatting | `git diff --check` and Alejandra checks passed. |
| Temporary activation and real sudo success | Passed after the user set a Linux password. Home Manager initially rejected two existing manual symlinks; retaining them as `.codex/AGENTS.md.hm-backup` and `.claude/CLAUDE.md.hm-backup` allowed activation to finish with status 0. Their original target, `.config/ai/AGENTS.md`, was untouched. Uncached `sudo true` succeeded with the Hello PAM stack active. |
| Active sudo password fallback | The prompt was observed after a real Hello attempt and immediately when removing `WSL_INTEROP` or setting an SSH session marker. The user confirmed that `sudo -k; env -u WSL_INTEROP sudo true` succeeds with their Linux password in their own terminal. No password was supplied to or collected by the agent. |
| Permanent activation | `nixos-rebuild switch --flake path:/home/maicol07/.config/nixos#maicol07-pc` completed with status 0. Active generation and system profile both point to the tested configuration; Home Manager is active. |
| Windows Terminal, IDE terminal and remote SSH end-to-end | Pending manual checks after activation. Bounded waiting and SSH detection were verified in the isolated launcher/PAM tests. |

Changed files: `wsl.nix`, `flake.nix`, `README.md`.
New files: `modules/wsl-windows-hello.nix`, `pkgs/wsl-hello-sudo/default.nix`,
`tests/wsl-windows-hello.py`, this document and the enrolled public key
`keys/maicol07-pc-wsl-hello.pem`. The flake lock is unchanged. The public key is
versioned; the private Windows credential is never copied into this repository.

Relevant configuration diff:

```diff
+  imports = [ ./modules/wsl-windows-hello.nix ];
   wsl = {
     enable = true;
+    windowsHello = {
+      enable = true;
+      publicKey = let
+        path = ./keys + "/${hostname}-wsl-hello.pem";
+      in if builtins.pathExists path then path else null;
+    };
```

The module exposes only `enable` and `publicKey`. Nix manages the compiled Linux
module, generated config, trusted public-key symlink, PAM ordering, sudo policy
and helper commands. Windows retains the executable and private credential.
The source tree has `modules/`, `pkgs/wsl-hello-sudo/`, `tests/`, `docs/` and
`keys/`, with the existing flat host configuration unchanged in structure.

The tested generation is now the persistent system default on `maicol07-pc`.
Optional manual coverage remains for every terminal application and a real remote
SSH connection; simulated SSH detection and its immediate password prompt passed.
Resolve the unrelated server journald assertion separately if a whole-flake check
is required. The binary Windows release remains a documented provenance limit.
