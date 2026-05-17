{
  imports = [
    ./buck2-dep-format/package.nix
    ./buck2/package.nix
    ./xip-elf/package.nix
  ];

  perSystem =
    {
      pkgs,
      ...
    }:

    {
      packages = {
        rust-bin = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      };
    };
}
