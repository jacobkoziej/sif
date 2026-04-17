{
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:

    let
      inherit (pkgs.rustPlatform) buildRustPackage;
      inherit (lib) cleanSource;

    in
    {
      packages = {
        xip-elf = buildRustPackage {
          pname = "xip-elf";
          version = "0.0.0";

          src = cleanSource ./.;

          cargoLock.lockFile = ./Cargo.lock;

          meta = with lib; {
            description = "generate ELF headers suitable for XIP";
            homepage = "https://github.com/jacobkoziej/sif/tree/master/tools/xip-elf";
            license = licenses.mpl20;
            maintainers = with maintainers; [
              jacobkoziej
            ];
            mainProgram = "buck2-dep-format";
          };
        };
      };
    };
}
