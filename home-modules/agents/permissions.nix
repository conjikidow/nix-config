# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ config, lib, ... }:

let
  cfg = config.local.agents;

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
in
{
  options.local.agents = {
    permissions = lib.genAttrs [ "allow" "ask" "deny" ] (
      kind:
      lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Permission rules for coding agents, in the Claude Code rule syntax, that apply as `${kind}`.
          Claude Code gets them in its user settings, and Codex gets the rules it can express.
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
  };

  config.local.agents.permissions.deny = lib.concatMap readDenyRules cfg.readDenyExcept;
}
