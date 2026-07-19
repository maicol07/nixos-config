self: super: let
  lib = super.lib;
  stdenv = super.stdenv;
  rustPlatform = super.rustPlatform;
  onnxruntime = super.onnxruntime;
  cffi = super.python3Packages.cffi;
  libiconv = super.libiconv;
  python3Packages = super.python3Packages;
  headroomPkg = python3Packages.buildPythonPackage rec {
    pname = "headroom-ai";
    version = "0.24.0";
    pyproject = true;

    src = super.fetchFromGitHub {
      owner = "chopratejas";
      repo = "headroom";
      tag = "v${version}";
      hash = "sha256-765aekIjf9oMdY7prRT2CqeDGtXEEDQn43GQkaTeAaY=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit pname version src;
      hash = "sha256-WQBvil0bsS6/Z6b+uRauwOQq4VZ57VwAoghcyFdVgLE=";
    };

    postPatch = ''
      substituteInPlace crates/headroom-core/Cargo.toml \
        --replace-fail \
        '"ort-download-binaries-rustls-tls"' '"ort-load-dynamic"'
      substituteInPlace headroom/cli/wrap.py \
        --replace-fail \
        '[sys.executable, "-m", "headroom.cli", "proxy",' \
        '["headroom", "proxy",'
    '';

    nativeBuildInputs = [ cffi ] ++ (with rustPlatform; [ cargoSetupHook maturinBuildHook ]);
    buildInputs = [ onnxruntime ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

    env = {
      ORT_DYLIB_PATH = "${onnxruntime}/lib/libonnxruntime${stdenv.hostPlatform.extensions.sharedLibrary}";
      PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1";
    };

    propagatedBuildInputs = with python3Packages; [
      click
      fastapi
      h2
      httpx
      litellm
      opentelemetry-api
      pydantic
      rich
      tiktoken
      uvicorn
    ] ++ lib.optionals (lib.versionOlder python3Packages.python.pythonVersion "3.11") [ tomli ];

    pythonRelaxDeps = [ "litellm" ];
    pythonRemoveDeps = [ "ast-grep-cli" ];
    doCheck = false;
    pythonImportsCheck = [ "headroom" ];

    meta = {
      description = "Context compression layer for LLM applications — 60–95% fewer tokens";
      homepage = "https://github.com/chopratejas/headroom";
      changelog = "https://github.com/chopratejas/headroom/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.asl20;
      maintainers = [];
      platforms = lib.platforms.unix;
    };
  };
in {
  python3Packages = python3Packages // {
    headroom = headroomPkg;
  };
  headroom = headroomPkg;
}
