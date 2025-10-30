# SPDX-License-Identifier: MPL-2.0

{
  description = "a preemptive rtos";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

      imports = [
        ./nix/dev-shells.nix
      ];

      perSystem =
        {
          pkgs,
          ...
        }:

        {
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
