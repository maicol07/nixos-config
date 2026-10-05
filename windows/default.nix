{
  pkgs,
  home,
}: let
  inherit (pkgs) lib;
  git = home.programs.git;
  # Translate only known executable paths. New Linux-only values fail the build.
  commands = [
    (lib.getExe home.programs.gh.package)
    (lib.getExe home.programs.delta.package)
    (lib.getExe git.lfs.package)
    git.signing.signer
    git.settings.core.sshCommand
  ];
  nativeCommands = ["gh" "delta" "git-lfs" "C:/Users/Maicol/AppData/Local/Microsoft/WindowsApps/op-ssh-sign.exe" "C:/Windows/System32/OpenSSH/ssh.exe"];
  native = value:
    if builtins.isString value
    then lib.replaceStrings commands nativeCommands value
    else if builtins.isList value
    then map native value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: native) value
    else value;
  includes =
    lib.imap0 (index: include: {
      name = ".gitconfig-include-${toString index}";
      source = pkgs.writeText "windows-git-include-${toString index}" (lib.generators.toGitINI (native include.contents));
      config = lib.generators.toGitINI (
        if include.condition == null
        then {include.path = "./.gitconfig-include-${toString index}";}
        else {includeIf.${include.condition}.path = "./.gitconfig-include-${toString index}";}
      );
    })
    git.includes;
  shared = root: target: source: {inherit root target source;};
  files =
    [
      (shared "userprofile" ".gitconfig" (pkgs.writeText "windows-gitconfig" (
        lib.generators.toGitINI (native git.iniContent)
        + lib.concatMapStrings (include: "\n" + include.config) includes
      )))
      (shared "userprofile" ".config/starship.toml" home.home.file."${home.xdg.configHome}/starship.toml".source)
      (shared "userprofile" ".config/starship-minimal.toml" home.home.file.".config/starship-minimal.toml".source)
      (shared "userprofile" ".config/micro/settings.json" home.xdg.configFile."micro/settings.json".source)
      (shared "appdata" "lsd/config.yaml" home.xdg.configFile."lsd/config.yaml".source)
      (shared "userprofile" ".codex/AGENTS.md" (builtins.path {path = home.home.file.".codex/AGENTS.md".source;}))
      (shared "userprofile" ".claude/CLAUDE.md" (builtins.path {path = home.home.file.".claude/CLAUDE.md".source;}))
    ]
    ++ map (include: shared "userprofile" include.name include.source) includes;
  entries = lib.imap0 (index: file: file // {source = "files/${toString index}";}) files;
in
  assert lib.assertMsg (lib.all (include: include.contents != {}) git.includes)
  "Windows Git includes must have declarative contents, not external paths.";
    pkgs.runCommand "windows-dotfiles" {} ''
      mkdir -p "$out/files"
      ${lib.concatStrings (lib.imap0 (index: file: ''
          cp ${lib.escapeShellArg (toString file.source)} "$out/files/${toString index}"
        '')
        files)}
      cp ${pkgs.writeText "windows-dotfiles-manifest.json" (builtins.toJSON entries)} "$out/manifest.json"
      if ${pkgs.gnugrep}/bin/grep -rqE '/nix/store/|/mnt/[a-z]/|\\\\wsl\.(localhost|\$)' "$out/files"; then
        echo 'Windows dotfiles contain a Linux runtime path; define a platform override.' >&2
        exit 1
      fi
    ''
