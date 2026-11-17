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

  letters = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz";

  # Class of the digits, the lowercase letters other than `excluded`, and `._~+@-`.
  charClass = excluded: "[0-9" + lib.concatStrings (lib.subtractLists excluded letters) + "._~+@-]";

  heads = words: lib.unique (map (lib.substring 0 1) words);
  tails =
    c: words: map (w: lib.substring 1 (lib.stringLength w) w) (lib.filter (lib.hasPrefix c) words);

  # Patterns matching every non-empty continuation of `prefix` except the given words, with positive classes only.
  exceptPatterns =
    prefix: words:
    let
      rest = lib.remove "" words;
    in
    if rest == [ ] then
      [ "${prefix}?*" ]
    else
      [ "${prefix}${charClass (heads rest)}*" ]
      ++ lib.concatMap (
        c:
        let
          sub = tails c rest;
        in
        lib.optional (!lib.elem "" sub) "${prefix}${c}" ++ exceptPatterns "${prefix}${c}" sub
      ) (heads rest);

  readDenyRules =
    entry:
    let
      exceptions = lib.unique entry.exceptions;
    in
    map (pattern: "Read(${pattern})") (
      if exceptions == [ ] then
        [ "${entry.patternPrefix}*" ]
      else
        [ entry.patternPrefix ] ++ exceptPatterns entry.patternPrefix exceptions
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
          A rule already present in the settings is left to the user and keeps its place before the managed rules,
          so a `!` rule that the settings already hold does not carve out of a managed rule added after it.
          To remove every managed rule and hook, empty these options and switch once before removing the module.
        '';
      }
    );

    readDenyExcept = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            patternPrefix = lib.mkOption {
              type = lib.types.str;
              description = "Read rule pattern that the denied file names start with, such as `//**/.env.`.";
            };
            exceptions = lib.mkOption {
              type = lib.types.listOf (lib.types.strMatching "[a-z]+");
              description = "Lowercase words that may follow `patternPrefix` and stay readable.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Read deny rules, added to `permissions.deny`, for every file name that starts with `patternPrefix`,
        except the names that continue with exactly one of `exceptions`.
        The exceptions also cover their uppercase spellings.
        A name whose first character after the shared part of an exception is outside `[0-9a-z._~+@-]`
        is not denied.
      '';
    };

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
    local.claudeCode.managedSettings.permissions.deny = lib.concatMap readDenyRules cfg.readDenyExcept;

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
