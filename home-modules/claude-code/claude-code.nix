# SPDX-FileCopyrightText: 2026 Intelligent Space Systems Laboratory, The University of Tokyo
# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ lib, ... }:

{
  imports = [ ./managed-settings.nix ];

  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md;
    rulesDir = ./rules;
    skills = ./skills;
  };

  local.claudeCode.managedSettings = lib.importJSON ./managed-settings.json;
}
