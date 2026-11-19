# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ lib, ... }:

{
  imports = [
    ./permissions.nix
    ./subcommand-guard.nix
  ];

  local.agents = lib.importJSON ./permissions.json;
}
