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
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      imports = [
        ./nix
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
