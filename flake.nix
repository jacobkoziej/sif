# SPDX-License-Identifier: MPL-2.0

{
  description = "a preemptive rtos";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nur-packages = {
      url = "github:jacobkoziej/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        ./tools
      ];

      perSystem =
        {
          pkgs,
          system,
          ...
        }:

        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;

            overlays = [
              inputs.nur-packages.overlays.default
              inputs.rust-overlay.overlays.default
            ];
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
