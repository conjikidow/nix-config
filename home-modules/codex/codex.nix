# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

{ lib, ... }:

let
  agents = ../agents;

  conventions = [
    "chat-math"
    "git-commands"
    "language"
    "official-sources"
    "safety"
    "tooling"
    "workflow-checkpoints"
  ];

  conventionSkills = {
    branch-naming = "Conventions for branch names. Use when creating or naming a Git branch.";
    commit-messages = "Conventions for commit messages and pull request titles. Use when writing either.";
    markdown = "Line break conventions for Markdown sources. Use when writing or editing a Markdown file.";
    pull-requests = "Conventions for pull requests. Use when creating a pull request or writing its title or body.";
    typst = "Line break conventions for Typst sources. Use when writing or editing a Typst file.";
  };

  rule = name: builtins.readFile (agents + "/rules/${name}.md");
in
{
  imports = [ ./permissions.nix ];

  programs.codex = {
    context = lib.concatStringsSep "\n" ([ (builtins.readFile ./AGENTS.md) ] ++ map rule conventions);

    skills =
      lib.mapAttrs (name: _: agents + "/skills/${name}") (builtins.readDir (agents + "/skills"))
      // lib.mapAttrs (name: description: ''
        ---
        name: ${name}
        description: ${description}
        ---

        ${rule name}
      '') conventionSkills;
  };
}
