# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{
  config,
  lib,
  pkgs,
  ...
}:

let
  guard = pkgs.writers.writePython3Bin "claude-code-subcommand-guard" {
    libraries = [
      pkgs.python3Packages.tree-sitter
      pkgs.python3Packages.tree-sitter-bash
    ];
    doCheck = false;
  } (builtins.readFile ./subcommand-guard.py);

  guardPath = "claude-code/subcommand-guard";
  rulesPath = "claude-code/permission-rules.json";
in
{
  xdg.dataFile = {
    ${guardPath}.source = "${guard}/bin/claude-code-subcommand-guard";
    ${rulesPath}.source = pkgs.writeText "claude-code-permission-rules.json" (
      builtins.toJSON config.local.claudeCode.managedSettings.permissions
    );
  };

  local.claudeCode.managedSettings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = lib.escapeShellArgs [
            "${config.xdg.dataHome}/${guardPath}"
            "${config.xdg.dataHome}/${rulesPath}"
          ];
          timeout = 30;
          onFailure = "block";
        }
      ];
    }
  ];
}
