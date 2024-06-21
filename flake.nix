{
  description = "sif";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        llvm = pkgs.llvmPackages_latest;
        python = pkgs.python312;

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            llvm.clang-unwrapped
            pkgs.nixpkgs-fmt
            python
          ];
        };
      }
    );
}
