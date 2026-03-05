{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:

    {
      devShells.default = pkgs.mkShellNoCC (
        let
          pre-commit-bin = "${lib.getBin pkgs.pre-commit}/bin/pre-commit";

        in
        {
          packages = with pkgs; [
            black
            buck2
            commitlint-rs
            mdformat
            pre-commit
            rustfmt
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
