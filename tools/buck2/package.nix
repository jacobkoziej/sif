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

      version = "2026-07-01";

      src = fetchFromGitHub {
        owner = "facebook";
        repo = "buck2";
        tag = version;
        hash = "sha256-OUry9bJjE9R/9hT/GK4oOu/hVtQJrKABrSkn8osWFfk=";
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
              "filedescriptor-0.8.3" = "sha256-V6WvkNZryYofarsyfcmsuvtpNJ/c3O+DmOKNvoYPbmA=";
              "finl_unicode-1.3.0" = "sha256-38S6XH4hldbkb6NP+s7lXa/NR49PI0w3KYqd+jPHND0=";
              "perf-event-0.4.8" = "sha256-Mvfp41Q9g9Z9xgdzFEdIdH/96YeCxrrSl2Vsm6geGMQ=";
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
            "--workspace"
            "--exclude=dice-examples"
            "--"
            "--skip=net_io::tests::test_network_collector"
            "--skip=version_control_revision::tests::test_get_git_revision_matches_head"
            "--skip=version_control_revision::tests::test_get_git_status_clean"
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
