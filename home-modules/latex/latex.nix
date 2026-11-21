# SPDX-FileCopyrightText: 2026 Intelligent Space Systems Laboratory, The University of Tokyo
# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ pkgs, ... }:

{
  home.packages = [
    (pkgs.texliveSmall.withPackages (ps: [
      ps.collection-bibtexextra
      ps.collection-langjapanese
      ps.collection-latexextra
      ps.collection-mathscience
      ps.latexmk
    ]))
  ];

  xdg.configFile."latexmk/latexmkrc".text = ''
    $pdf_mode = 4;
    $lualatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
    $out_dir = 'build';
    $bibtex = 'upbibtex %O %S';
  '';
}
