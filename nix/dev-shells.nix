{
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:

    let
      inherit (lib) getExe;

    in
    {
      devShells.default = pkgs.mkShellNoCC (
        let
          pre-commit-bin = getExe pkgs.pre-commit;

          buck2 = pkgs.writeShellScriptBin "buck2" ''
            exec \
              "${getExe self'.packages.buck2}" \
              ${"$"}{BUCK2FLAGS:+"$BUCK2FLAGS"} \
              ${"$"}{@:+"$@"} \
              ;
          '';

        in
        {
          packages = with pkgs; [
            black
            buck2
            commitlint-rs
            mdformat
            pre-commit
            rustfmt
            statix
            toml-sort
            treefmt
            yamlfmt
            yamllint
          ];

          shellHook = ''
            ${pre-commit-bin} install --allow-missing-config > /dev/null
          '';
        }
      );
    };
}
