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
        buck2-dep-format = buildRustPackage {
          pname = "buck2-dep-format";
          version = "0.0.0";

          src = cleanSource ./.;

          cargoLock.lockFile = ./Cargo.lock;

          meta = with lib; {
            description = "buck2 dependency file formatter";
            homepage = "https://github.com/jacobkoziej/sif/tree/master/tools/buck2-dep-format";
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
