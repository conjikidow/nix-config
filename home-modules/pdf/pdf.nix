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
  home.packages = lib.mkMerge [
    [ pkgs.qpdf ]

    (lib.mkIf config.local.desktop.enable [
      pkgs.diffpdf
      pkgs.pdfarranger
      pkgs.pdfpc
    ])
  ];
}
