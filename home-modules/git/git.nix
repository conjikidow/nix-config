# SPDX-FileCopyrightText: 2026 Intelligent Space Systems Laboratory, The University of Tokyo
# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ config, lib, ... }:

let
  isslConfigHome = "${config.xdg.configHome}/issl";
in
{
  xdg.configFile."git/config".text = lib.mkBefore (
    lib.generators.toGitINI {
      include.path = "${isslConfigHome}/git/.gitconfig";
    }
  );

  programs.git = {
    enable = true;

    settings = {
      # Personal identity:
      user.name = "Riki Nakamura";
      user.email = "riki.nakamura.edu@gmail.com";

      alias = {
        ch = "checkout";
        cm = "commit";
        cr = "clone --recursive";
        st = "status";
        sw = "switch";
      };

      commit.verbose = true;

      help.autocorrect = 1;

      # Use SSH for GitHub by default.
      # Comment out this block if you prefer HTTPS with Git Credential Manager or a personal access token.
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };

  };
}
