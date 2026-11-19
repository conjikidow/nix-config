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
  codexHome = config.home.sessionVariables.CODEX_HOME or "${config.home.homeDirectory}/.codex";

  inherit (config.local.agents) permissions;

  # Whether a Bash rule body matches every command that starts with `words`.
  coversPrefix =
    body: words:
    let
      regex = lib.concatMapStringsSep ".*" lib.escapeRegex (lib.splitString "*" body);
      command = lib.concatStringsSep " " words;
    in
    lib.hasSuffix "*" body
    && lib.any (text: builtins.match regex text != null) [
      command
      "${command} "
    ];

  # Codex prefix patterns of a Bash rule, with its wildcards removed and with them read as spaces,
  # only those the rule covers when `exact` is true.
  prefixPatterns =
    exact: rule:
    let
      body = lib.removeSuffix ")" (lib.removePrefix "Bash(" rule);
      words =
        wildcard:
        lib.filter (word: word != "") (lib.splitString " " (lib.replaceStrings [ "*" ] [ wildcard ] body));
    in
    lib.filter (pattern: !exact || coversPrefix body pattern) (
      lib.optionals
        (lib.hasPrefix "Bash(" rule && lib.hasSuffix ")" rule && !lib.hasPrefix "*" body && words "" != [ ])
        (
          map words [
            ""
            " "
          ]
        )
    );

  prefixRules =
    decision: exact: rules:
    map (pattern: "prefix_rule(pattern = ${builtins.toJSON pattern}, decision = \"${decision}\")") (
      lib.unique (lib.concatMap (prefixPatterns exact) rules)
    );

  rulesFile = pkgs.writeText "agents.rules" (
    lib.concatLines (
      [ "# Generated from the agent permission rules." ]
      ++ prefixRules "forbidden" true (lib.filter (lib.hasInfix "*") permissions.deny)
      ++ prefixRules "prompt" false permissions.ask
    )
  );

  hooksFile = pkgs.writeText "codex-hooks.json" (
    builtins.toJSON {
      hooks.PreToolUse = [
        {
          matcher = "^Bash$";
          hooks = [
            {
              type = "command";
              command = "${config.local.agents.subcommandGuard.command} --deny-only";
              timeout = 30;
            }
          ];
        }
      ];
    }
  );
in
{
  home.activation.installCodexPermissions = lib.mkIf config.programs.codex.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run install -D -m 0444 ${rulesFile} "${codexHome}/rules/agents.rules"
      run install -D -m 0444 ${hooksFile} "${codexHome}/hooks.json"
    ''
  );
}
