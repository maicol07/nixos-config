"""Run as root inside a private mount namespace, never against the active PAM stack.

sudo unshare --mount --propagation private python3 tests/wsl-windows-hello.py INTEGRATION PAM
INTEGRATION is config.system.build.wslWindowsHello; PAM is the nixpkgs pam store path.
"""

import ctypes
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import tempfile
import time


def run(*args: str, **kwargs: object) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, **kwargs)


if os.geteuid() != 0 or os.readlink("/proc/self/ns/mnt") == os.readlink("/proc/1/ns/mnt"):
    raise SystemExit("Requires root and a private mount namespace")

integration, pam = map(Path, sys.argv[1:])
run("mount", "-t", "tmpfs", "-o", "mode=1777", "tmpfs", "/tmp")
with tempfile.TemporaryDirectory(prefix="wsl-hello-test-") as temporary:
    directory = Path(temporary)
    etc = directory / "etc"
    etc.mkdir()
    for name in ("passwd", "group", "nsswitch.conf"):
        (etc / name).write_bytes((Path("/etc") / name).read_bytes())
    password = secrets.token_hex(16)
    password_hash = run("openssl", "passwd", "-6", "-stdin", input=password.encode(),
                        stdout=subprocess.PIPE).stdout.decode().strip()
    (etc / "shadow").write_text(f"root:{password_hash}:20000:0:99999:7:::\n")
    (etc / "shadow").chmod(0o600)
    hello = etc / "pam_wsl_hello"
    keys = hello / "public_keys"
    keys.mkdir(parents=True)
    services = directory / "services"
    services.mkdir()
    private = directory / "private.pem"
    public = keys / "pam_wsl_hello_root.pem"
    run("openssl", "genpkey", "-algorithm", "RSA", "-pkeyopt", "rsa_keygen_bits:2048",
        "-out", str(private), stderr=subprocess.DEVNULL)
    run("openssl", "pkey", "-in", str(private), "-pubout", "-out", str(public))
    public_bytes = public.read_bytes()
    run("mount", "--bind", str(etc), "/etc")

    class Message(ctypes.Structure):
        _fields_ = [("style", ctypes.c_int), ("text", ctypes.c_char_p)]

    class Response(ctypes.Structure):
        _fields_ = [("text", ctypes.c_void_p), ("code", ctypes.c_int)]

    callback_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int,
                                    ctypes.POINTER(ctypes.POINTER(Message)),
                                    ctypes.POINTER(ctypes.POINTER(Response)), ctypes.c_void_p)

    class Conversation(ctypes.Structure):
        _fields_ = [("callback", callback_type), ("data", ctypes.c_void_p)]

    libc = ctypes.CDLL(None)
    libc.calloc.restype = ctypes.c_void_p
    libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]
    libc.strdup.restype = ctypes.c_void_p
    libc.strdup.argtypes = [ctypes.c_char_p]
    library = ctypes.CDLL(str(pam / "lib/libpam.so.0"))
    library.pam_start_confdir.argtypes = [ctypes.c_char_p, ctypes.c_char_p,
                                         ctypes.POINTER(Conversation), ctypes.c_char_p,
                                         ctypes.POINTER(ctypes.c_void_p)]
    library.pam_authenticate.argtypes = [ctypes.c_void_p, ctypes.c_int]
    library.pam_end.argtypes = [ctypes.c_void_p, ctypes.c_int]
    prompts = []

    @callback_type
    def converse(count, messages, responses, data):
        allocated = ctypes.cast(libc.calloc(count, ctypes.sizeof(Response)),
                                ctypes.POINTER(Response))
        for index in range(count):
            if messages[index].contents.style in (1, 2):
                prompts.append(messages[index].contents.style)
                allocated[index].text = libc.strdup(password.encode())
        responses[0] = allocated
        return 0

    conversation = Conversation(converse, None)
    module = integration / "lib/security/pam_wsl_hello.so"
    unix = pam / "lib/security/pam_unix.so"
    deny = pam / "lib/security/pam_deny.so"
    (services / "hello").write_text(f"auth sufficient {module}\n"
                                    f"auth sufficient {unix} likeauth try_first_pass\n"
                                    f"auth required {deny}\n")
    bridge = directory / "bridge"

    def authenticate(name: str, expect_prompt: bool, success: bool = True) -> None:
        prompts.clear()
        handle = ctypes.c_void_p()
        assert library.pam_start_confdir(b"hello", b"root", ctypes.byref(conversation),
                                         str(services).encode(), ctypes.byref(handle)) == 0
        start = time.monotonic()
        result = library.pam_authenticate(handle, 0)
        library.pam_end(handle, result)
        assert (result == 0) == success, (name, result)
        assert bool(prompts) == expect_prompt, (name, prompts)
        print(f"PASS {name}: password prompts={len(prompts)}, elapsed={time.monotonic()-start:.2f}s",
              flush=True)

    def configure(body: str, executable: bool = True) -> None:
        bridge.write_text("#!/run/current-system/sw/bin/bash\n" + body + "\n")
        bridge.chmod(0o700 if executable else 0o600)
        (hello / "config").write_text(f'authenticator_path = "{bridge}"\nwin_mnt = "/tmp"\n')

    configure(f'exec openssl dgst -sha256 -sign "{private}"')
    authenticate("valid challenge signature", False)
    configure("printf invalid-signature")
    authenticate("invalid signature falls back", True)
    for name, code in (("cancelled", 176), ("failed", 178), ("not configured", 172),
                       ("unsupported", 170)):
        configure(f"exit {code}")
        authenticate(name, True)
    bridge.unlink()
    authenticate("missing bridge", True)
    configure("exit 0", executable=False)
    authenticate("non-executable bridge", True)
    public.unlink()
    authenticate("missing key", True)
    public.write_text("invalid PEM")
    authenticate("invalid key", True)
    public.write_bytes(public_bytes)
    (hello / "config").unlink()
    authenticate("missing config", True)
    (hello / "config").write_text("invalid TOML")
    authenticate("invalid config", True)
    launcher = integration / "bin/wsl-hello-authenticate"
    (hello / "config").write_text(f'authenticator_path = "{launcher}"\nwin_mnt = "/tmp"\n')
    os.environ["SSH_CONNECTION"] = "127.0.0.1 1 127.0.0.1 22"
    authenticate("SSH bypasses Windows Hello", True)
    del os.environ["SSH_CONNECTION"]
    interop = os.environ.pop("WSL_INTEROP", None)
    authenticate("missing interop socket", True)
    if interop:
        os.environ["WSL_INTEROP"] = interop
    # Exercise the actual launcher with controlled external processes in this namespace.
    powershell = Path("/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe")
    fake_powershell = directory / "powershell"
    fake_powershell.write_text('#!/run/current-system/sw/bin/bash\ncat > /dev/null\nprintf "C:\\\\test\\n"\n')
    fake_powershell.chmod(0o700)
    run("mount", "--bind", str(fake_powershell), str(powershell))
    appdata = directory / "appdata"
    bridge_directory = appdata / "Programs/wsl-hello-sudo"
    bridge_directory.mkdir(parents=True)
    fake_wslpath = directory / "wslpath"
    fake_wslpath.write_text(f'#!/run/current-system/sw/bin/bash\nprintf "%s\\n" "{appdata}"\n')
    fake_wslpath.chmod(0o700)
    run("mount", "--bind", str(fake_wslpath), "/sbin/wslpath")
    interop_socket = socket.socket(socket.AF_UNIX)
    interop_socket.bind(str(directory / "interop"))
    os.environ["WSL_INTEROP"] = str(directory / "interop")
    authenticate("launcher with missing Windows bridge", True)
    windows_bridge = bridge_directory / "WindowsHelloBridge.exe"
    windows_bridge.write_text('#!/run/current-system/sw/bin/bash\nexit 176\n')
    windows_bridge.chmod(0o600)
    authenticate("launcher with non-executable Windows bridge", True)
    windows_bridge.chmod(0o700)
    authenticate("launcher propagates Windows cancellation", True)
    windows_bridge.write_text(f'#!/run/current-system/sw/bin/bash\nexec openssl dgst -sha256 -sign "{private}"\n')
    authenticate("launcher preserves signed response bytes", False)
    disabled = directory / "disabled-interop"
    disabled.write_text("disabled\n")
    run("mount", "--bind", str(disabled), "/proc/sys/fs/binfmt_misc/WSLInterop")
    authenticate("disabled WSL interop", True)
    run("umount", "/proc/sys/fs/binfmt_misc/WSLInterop")
    windows_bridge.write_text('#!/run/current-system/sw/bin/bash\nexec sleep 60\n')
    started = time.monotonic()
    authenticate("unresponsive Windows bridge times out", True)
    assert 29 <= time.monotonic() - started < 35
    interop_socket.close()
    windows_bridge.write_text('#!/run/current-system/sw/bin/bash\nexit 176\n')
    password = secrets.token_hex(16)
    authenticate("incorrect Linux password is rejected", True, success=False)
    print("21 isolated PAM integration checks passed", flush=True)
