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
    text = ''
      settings="$1"
      state="$2"
      next="$3"

      if [ -L "$settings" ]; then
        echo "warning: $settings is a symbolic link; the managed settings were not merged" >&2
        exit 0
      fi

      skip() {
        echo "warning: $1; the managed settings were not merged" >&2
        exit 0
      }

      if [ -e "$settings" ] && ! jq -e 'type == "object"' "$settings" > /dev/null 2>&1; then
        skip "$settings is not a JSON object"
      fi

      previous=/dev/null
      if [ -e "$state" ]; then
        if ! jq -e 'type == "object"' "$state" > /dev/null 2>&1; then
          skip "$state is not a JSON object (remove it to merge again)"
        fi
        previous="$state"
      fi

      mkdir -p "$(dirname "$settings")" "$(dirname "$state")"
      work=""
      state_tmp=""
      trap 'rm -rf "$work" "$state_tmp"' EXIT
      work="$(mktemp -d "$(dirname "$settings")/.managed-settings.XXXXXX")"
      state_tmp="$(mktemp "$state.XXXXXX")"

      snapshot() {
        if [ -e "$settings" ]; then
          sha256sum < "$settings"
        else
          echo missing
        fi
      }

      for _ in 1 2 3; do
        before="$(snapshot)"
        if [ -e "$settings" ]; then
          cp "$settings" "$work/current.json"
        else
          echo '{}' > "$work/current.json"
        fi

        if ! jq --slurpfile prev "$previous" --slurpfile next "$next" -f ${./merge-settings.jq} \
          "$work/current.json" > "$work/result.json"; then
          skip "merging into $settings failed"
        fi

        jq '.settings' "$work/result.json" > "$work/settings.json"
        jq '.added' "$work/result.json" > "$state_tmp"
        if [ -e "$settings" ]; then
          chmod "$(stat -c %a "$settings")" "$work/settings.json"
        fi
        chmod 0644 "$state_tmp"

        if [ "$(snapshot)" = "$before" ]; then
          mv "$work/settings.json" "$settings"
          mv "$state_tmp" "$state"
          exit 0
        fi
      done

      skip "$settings kept changing while the managed settings were merged"
    '';
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
        ]
      }
    '';
  };
}
