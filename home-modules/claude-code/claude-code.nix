# SPDX-FileCopyrightText: 2026 Intelligent Space Systems Laboratory, The University of Tokyo
# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ config, ... }:

{
  imports = [ ./managed-settings.nix ];

  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md;
    rulesDir = ../agents/rules;
    skills = ../agents/skills;
  };

  local.claudeCode.managedSettings = {
    inherit (config.local.agents) permissions;

    hooks.PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            inherit (config.local.agents.subcommandGuard) command;
            timeout = 30;
            onFailure = "block";
          }
        ];
      }
    ];
  };
}
