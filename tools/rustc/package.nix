{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib) concatStringsSep;
      inherit (lib) hasPrefix;
      inherit (lib) importTOML;
      inherit (lib) removePrefix;
      inherit (lib) splitString;
      inherit (pkgs) fetchurl;
      inherit (pkgs) stdenv;
      inherit (pkgs) stdenvNoCC;

      rustToolchain = importTOML ../rust-toolchain.toml;

      version = removePrefix "nightly-" rustToolchain.toolchain.channel;
      targets = rustToolchain.targets or [ ];

      src = fetchurl {
        url = "https://static.rust-lang.org/dist/${version}/rustc-nightly-src.tar.gz";
        hash = "sha256-pkhYkFtR/GQiUAHWWUuejMZabhbffphMEbt+aBVfvYk=";
        passthru.isReleaseTarball = true;
      };

      bootstrapToolchain = pkgs.rust-bin.nightly.${version}.default;

      insertTargets =
        flag:
        if hasPrefix "--target=" flag then
          let
            baseTargets = splitString "," (removePrefix "--target=" flag);
            init = lib.init baseTargets;
            last = lib.last baseTargets;
          in
          "--target=${concatStringsSep "," (init ++ targets ++ [ last ])}"
        else
          flag;

      setNightly =
        flag: if hasPrefix "--release-channel=" flag then "--release-channel=nightly" else flag;

      updateFlags = flag: setNightly (insertTargets flag);

    in
    {
      packages = {
        rust-src = stdenvNoCC.mkDerivation {
          name = "rust-src-nightly-${version}";
          inherit src;

          phases = [
            "unpackPhase"
            "installPhase"
          ];

          installPhase = ''
            cp -r library/. $out
          '';
        };

        rustc =
          (pkgs.rustc.unwrapped.override {
            cargo = bootstrapToolchain;
            rustc = bootstrapToolchain // {
              inherit (pkgs.rustc) targetPlatforms;
              inherit (pkgs.rustc) targetPlatformsWithHostTools;
              inherit (pkgs.rustc) badTargetPlatforms;
            };
          }).overrideAttrs
            (old: {
              version = "nightly-${version}";
              inherit src;

              patches = old.patches ++ [
                ./disable-target-feature-warnings.patch
              ];

              configureFlags = map updateFlags old.configureFlags ++ [
                "--set=build.rustfmt=${bootstrapToolchain}/bin/rustfmt"
              ];
            });
      };
    };
}
