{ pkgs, lib, ... }: {
  programs.micro = {
    enable = true;
    settings = {
      autosu = true;
      clipboard = "terminal";
      colorscheme = "dukelight-tc";
      eofnewline = false;
      fastdirty = true;
      ignorecase = false;
      lsp.ignoreTriggerCharacters = "completion,signature";
      lsp.server = "python=pyls,go=gopls,php=intelephense,typescript=deno lsp,rust=rust-analyzer";
      mkparents = true;
      pluginChannels = [
        "https://raw.githubusercontent.com/Neko-Box-Coder/unofficial-plugin-channel/stable/channel.json"
      ];
    };
  };

  home.activation.installMicroPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${lib.getExe pkgs.micro} -plugin install aspell bookmark cheat detectindent editorconfig filemanager2 fish fzf gitStatus jump language_env language_ignore language_log lsp mdtree misspell nix quoter vcs wc wakatime
  '';
}