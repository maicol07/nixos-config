{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  stdenvNoCC,
  stdenv,
  pkg-config,
  openssl,
  pam,
}: let
  bridge = stdenvNoCC.mkDerivation {
    pname = "wsl-hello-sudo-windows-bridge";
    version = "3.0.0";
    src = fetchurl {
      url = "https://github.com/lzlrd/wsl-hello-sudo/releases/download/v3.0.0/release.tar.gz";
      hash = "sha256-0k+ydQ7z55JC6v3qsT9Tbhm/gWS/2fjfemZrr9DnLE4=";
    };
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      install -Dm755 build/WindowsHelloBridge.exe $out/share/wsl-hello-sudo/WindowsHelloBridge.exe
    '';
  };
in
  rustPlatform.buildRustPackage {
    pname = "wsl-hello-sudo";
    version = "3.0.0-unstable-2026-03-01";
    src = fetchFromGitHub {
      owner = "lzlrd";
      repo = "wsl-hello-sudo";
      rev = "3255c5244edf9ed337e79732539c9077207d3058";
      hash = "sha256-gulRQTFgLAgQDXVJVvxTKJzqst5GaUhlXNY73qFToYA=";
    };
    cargoHash = "sha256-FFWVs/JGa1rI+gQTC2GQ/nCYaVfUk8MGaxHiMm68tQY=";
    cargoBuildFlags = ["-p" "wsl_hello_pam"];
    # Upstream's old bindgen layout tests dereference null pointers on modern Rust.
    # Validate authentication with the isolated PAM integration test instead.
    doCheck = false;
    nativeBuildInputs = [pkg-config];
    buildInputs = [openssl pam];
    OPENSSL_NO_VENDOR = 1;
    postPatch = ''
      # Keep only the open challenge descriptor, including on launch/configuration errors.
      substituteInPlace wsl_hello_pam/src/auth.rs \
        --replace-fail '    fs::remove_file(challenge_tmpfile_path)?;' "" \
        --replace-fail '.open(challenge_tmpfile_path)?;' \
          '.open(challenge_tmpfile_path)?; fs::remove_file(challenge_tmpfile_path)?;'
      substituteInPlace wsl_hello_pam/src/auth.rs \
          --replace-fail 'Verifier::new(MessageDigest::sha256(), &hello_public_key).unwrap()' \
            'Verifier::new(MessageDigest::sha256(), &hello_public_key).map_err(HelloAuthenticationError::OpenSslError)?'
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libpam_wsl_hello.so $out/lib/security/pam_wsl_hello.so
      runHook postInstall
    '';
    passthru = {inherit bridge;};
    meta = {
      description = "Windows Hello authentication for sudo on WSL";
      homepage = "https://github.com/lzlrd/wsl-hello-sudo";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
