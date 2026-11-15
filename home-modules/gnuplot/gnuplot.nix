# SPDX-FileCopyrightText: 2026 Intelligent Space Systems Laboratory, The University of Tokyo
# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ pkgs, ... }:

{
  home.packages = [ pkgs.gnuplot ];

  xdg.configFile."gnuplot/gnuplotrc".text = ''
    set mxtics
    set mytics
    set mztics
    set grid xtics ytics ztics mxtics mytics mztics
    set xzeroaxis
    set yzeroaxis
    set zzeroaxis
  '';
}
