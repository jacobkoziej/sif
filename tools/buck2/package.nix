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
      inherit (pkgs.stdenv.hostPlatform) isLinux;

      version = "2026-10-15";

      src = fetchFromGitHub {
        owner = "facebook";
        repo = "buck2";
        tag = version;
        hash = "sha256-6uFr2rrn4of1BcG21VjpgsY8I1xlCRaKrDnbqcKoxPE=";
      };

      rust = pkgs.rust-bin.fromRustupToolchainFile "${src}/rust-toolchain.toml";

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
          inherit src;

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

            substituteInPlace Cargo.toml \
              --replace-fail \
                'bindgen = { git = "https://github.com/jsgf/rust-bindgen", rev = "4d385d21c160e6ee1f443aeb7e00528a1dc7fd44" }' \
                ""
          '';

          cargoHash = "sha256-yXHa9bAL/aVyRi0j+d78viI8zDF/Bcf/Eblw+rvbaRA=";

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
            "--skip=execution_types::revision::tests::revision_is_cached_per_instance"
            "--skip=execution_types::revision::tests::revision_searches_parents_and_falls_back_to_git"
            "--skip=execution_types::revision::tests::revisions_are_scoped_to_repo_root"
            "--skip=net_io::tests::test_network_collector"
            "--skip=tests::test_find_buck2_processes"
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
