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
  cfg = config.local.claudeCode.managedSettings;

  jsonType = (pkgs.formats.json { }).type;

  settingsFile = "${config.programs.claude-code.configDir}/settings.json";
  stateFile = "${config.xdg.stateHome}/claude-code/managed-settings.json";

  managedFile = pkgs.writeText "claude-code-managed-settings.json" (
    builtins.toJSON {
      permissions = lib.mapAttrs (_: lib.unique) cfg.permissions;
      hooks = lib.mapAttrs (_: lib.unique) cfg.hooks;
    }
  );

  mergeSettings = pkgs.writeShellApplication {
    name = "claude-code-merge-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ./merge-settings.sh;
  };
in
{
  options.local.claudeCode.managedSettings = {
    permissions = lib.genAttrs [ "allow" "ask" "deny" ] (
      kind:
      lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Permission rules merged into `permissions.${kind}` of the Claude Code user settings on every switch.
          A rule already present in the settings is left to the user.
          To remove every managed rule and hook, empty these options and switch once before removing the module.
        '';
      }
    );

    hooks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf jsonType);
      default = { };
      description = ''
        Hook matcher groups, keyed by hook event, merged into `hooks` of the Claude Code user settings on every switch.
        A managed group is matched as a whole:
        add your own hooks to the settings as a separate group, not inside a managed one.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion =
          config.programs.claude-code.settings == { } && config.programs.claude-code.marketplaces == { };
        message = "local.claudeCode.managedSettings merges into a writable settings.json; leave programs.claude-code.settings and programs.claude-code.marketplaces unset.";
      }
    ];

    home.activation.mergeClaudeCodeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe mergeSettings} ${
        lib.escapeShellArgs [
          settingsFile
          stateFile
          "${managedFile}"
          "${./merge-settings.jq}"
        ]
      }
    '';
  };
}
