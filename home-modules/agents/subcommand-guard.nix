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
  guard = pkgs.writers.writePython3Bin "agents-subcommand-guard" {
    libraries = [
      pkgs.python3Packages.tree-sitter
      pkgs.python3Packages.tree-sitter-bash
    ];
    doCheck = false;
  } (builtins.readFile ./subcommand-guard.py);

  guardPath = "agents/subcommand-guard";
  rulesPath = "agents/permission-rules.json";
in
{
  options.local.agents.subcommandGuard.command = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = lib.escapeShellArgs [
      "${config.xdg.dataHome}/${guardPath}"
      "${config.xdg.dataHome}/${rulesPath}"
    ];
    description = "Command that runs the subcommand guard on a PreToolUse hook input against the agent permission rules.";
  };

  config.xdg.dataFile = {
    ${guardPath}.source = "${guard}/bin/agents-subcommand-guard";
    ${rulesPath}.source = pkgs.writeText "agents-permission-rules.json" (
      builtins.toJSON config.local.agents.permissions
    );
  };
}
