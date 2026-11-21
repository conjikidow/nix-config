# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ config, pkgs, ... }:

{
  home.packages = [ pkgs.arduino-cli.pureGoPkg ];

  home.file.".arduino15/arduino-cli.yaml".text = ''
    directories:
      downloads: ${config.xdg.cacheHome}/arduino/staging
    updater:
      enable_notification: false
  '';
}
