# SPDX-License-Identifier: MPL-2.0

{
  description = "a preemptive rtos";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs:

    inputs.flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = import inputs.nixpkgs {
          inherit system;
        };

      in
      {
        devShells.default = pkgs.mkShellNoCC { };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
