# SPDX-FileCopyrightText: 2026 Intelligent Space Systems Laboratory, The University of Tokyo
# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.local.desktop.enable {
    fonts.fontconfig.enable = true;

    home.packages = [ pkgs.nerd-fonts.ubuntu-sans ];
  };
}
