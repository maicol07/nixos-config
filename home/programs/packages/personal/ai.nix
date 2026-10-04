{ ... }:
let
  instructions = ../../../AGENTS.md;
in
{
  home.file = {
    ".codex/AGENTS.md".source = instructions;
    ".claude/CLAUDE.md".source = instructions;
  };
}
