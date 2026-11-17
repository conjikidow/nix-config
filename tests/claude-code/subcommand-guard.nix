# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ pkgs, config }:

let
  inherit (config.xdg) dataFile;
in
pkgs.runCommand "claude-code-subcommand-guard-test" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 ${./subcommand-guard-test.py} \
    ${dataFile."claude-code/subcommand-guard".source} \
    ${dataFile."claude-code/permission-rules.json".source} \
    ${./subcommand-guard-cases.json}
  touch "$out"
''
