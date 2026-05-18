{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib) cleanSource;
      inherit (lib) optionalString;
      inherit (pkgs) fetchFromGitHub;
      inherit (pkgs) makeRustPlatform;
      inherit (pkgs.stdenv) isLinux;

      version = "2026-05-01";

      src = fetchFromGitHub {
        owner = "facebook";
        repo = "buck2";
        tag = version;
        hash = "sha256-C1BKfAIfyJ51OV60XpQpR2wDkxC6GDlf75LJ7KHITXs=";
      };

      rust = pkgs.rust-bin.fromRustupToolchainFile "${src}/rust-toolchain";

      rustPlatform = makeRustPlatform {
        cargo = rust;
        rustc = rust;
      };

      inherit (rustPlatform) buildRustPackage;

    in
    {
      packages = {
        buck2 = buildRustPackage (finalAttrs: {
          pname = "buck2";
          inherit version;

          src = pkgs.runCommand "src-with-lock" { } ''
            cp -r ${src} $out

            chmod -R +w $out

            cp ${./Cargo.lock} $out/Cargo.lock
          '';

          patches = [
            ./cli-cell-override.patch
            ./dynamic-cell-resolution.patch
            ./test_copy_file.patch
          ];

          postPatch = ''
            substituteInPlace app/buck2_client/src/commands/build/out.rs \
              --replace-fail "/bin/sleep" "${pkgs.coreutils}/bin/sleep"

            substituteInPlace app/buck2_execute_local/src/lib.rs \
              --replace-fail "/usr/bin/env bash" "${pkgs.bash}/bin/bash"
          '';

          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes = {
              "perf-event-0.4.8" = "sha256-Mvfp41Q9g9Z9xgdzFEdIdH/96YeCxrrSl2Vsm6geGMQ=";
              "probminhash-0.1.12" = "sha256-8IzGV6QDvyBPavICUB4j/VABBkplGa+sSsIz1OD35ik=";
              "sorted_vector_map-0.2.1" = "sha256-KM9HFTpP22VD05xOj2IEIoe3ITasHVAKTlZkCZGuhdw=";
            };
          };

          cargoBuildFlags = [
            "--bin=buck2"
          ];

          RUSTFLAGS = optionalString isLinux "--cfg=tokio_unstable";

          checkInputs = with pkgs; [
            cacert
          ];

          cargoTestFlags = [
            "--no-fail-fast"
            "--"
            "--skip=net_io::tests::test_network_collector"
          ];

          meta = with lib; {
            description = "Fast, hermetic, multi-language build system";
            homepage = "https://buck2.build";
            changelog = "https://github.com/facebook/buck2/releases/tag/${finalAttrs.version}";
            license = with licenses; [
              asl20
              mit
            ];
            maintainers = with maintainers; [
              jacobkoziej
            ];
            platforms = [
              "aarch64-darwin"
              "aarch64-linux"
              "x86_64-darwin"
              "x86_64-linux"
            ];
            mainProgram = "buck2";
          };
        });
      };
    };
}
