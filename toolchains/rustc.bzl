# SPDX-License-Identifier: MPL-2.0
#
# rustc.bzl -- rustc toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//tools/llvm/flags.bzl",
    "attributes",
    "cpu",
)
load("@sif//tools/rust:flags.bzl", "target")

rust_edition: str = "2024"

RustcDriver = enum("rustc", "miri")

RustcToolchainInfo = provider(
    fields={
        "tool": provider_field(RunInfo),
        "driver": provider_field(RustcDriver),
        "sysroot": provider_field(Artifact | str | None, default=None),
        "rustdoc": provider_field(RunInfo),
    },
)


# `rustc` does not currently export all target features specified with codegen
# options. To get around this we re-export these features with `--cfg`.
def generate_target_feature_cfgs(target_features: list[str]) -> list[str]:
    def not_disabled(target_feature: str) -> bool:
        return not target_feature.startswith("-")

    target_features = [t for t in target_features if not_disabled(t)]

    def map_to_cfg(target_feature: str) -> str:
        target_feature = target_feature.removeprefix("+")

        return '--cfg=target_feature="' + target_feature + '"'

    return ["-A", "explicit_builtin_cfgs_in_flags"] + map(map_to_cfg, target_features)


def _rustc_impl(ctx: AnalysisContext) -> list[Provider]:
    edition = "--edition=" + rust_edition
    target = "--target=" + ctx.attrs.target

    sysroot_artifact = ctx.attrs.sysroot

    if sysroot_artifact != None:
        if not isinstance(sysroot_artifact, str):
            sysroot_artifact = sysroot_artifact[DefaultInfo].default_outputs[0]

        sysroot = cmd_args(sysroot_artifact, format="--sysroot={}")

    else:
        sysroot = cmd_args()

    def map_codegen_option(x: tuple) -> str:
        option, value = x

        if isinstance(value, list):
            value = ",".join(value)

        return "--codegen=" + option + "=" + value

    codegen_options = map(map_codegen_option, ctx.attrs.codegen_options.items())
    target_feature_cfgs = generate_target_feature_cfgs(
        ctx.attrs.codegen_options.get("target-feature", []),
    )

    # `rustc` does not export codegen option `target-cpu` for conditional compilation
    # <https://github.com/rust-lang/rust/issues/44036>
    target_cpu = ctx.attrs.codegen_options.get("target-cpu")
    target_cpu = '--cfg=target_cpu="{}"'.format(target_cpu) if target_cpu else []

    def map_unstable_option(x: tuple) -> str:
        option, value = x

        return "-Z" + option + "=" + value

    unstable_options = map(map_unstable_option, ctx.attrs.unstable_options.items())

    common_flags = cmd_args(
        "--color=always",
        sysroot,
        edition,
        target,
        codegen_options,
        target_feature_cfgs,
        target_cpu,
        unstable_options,
    )

    rustc_cmd = cmd_args(
        ctx.attrs.tool[RunInfo].args,
        common_flags,
    )

    rustdoc_cmd = cmd_args(
        ctx.attrs.rustdoc[RunInfo].args,
        common_flags,
    )

    return [
        DefaultInfo(),
        RunInfo(
            args=rustc_cmd,
        ),
        RustcToolchainInfo(
            tool=RunInfo(
                args=rustc_cmd,
            ),
            driver=RustcDriver(ctx.attrs.driver),
            sysroot=sysroot_artifact,
            rustdoc=RunInfo(
                args=rustdoc_cmd,
            ),
        ),
    ]


rustc = rule(
    impl=_rustc_impl,
    is_toolchain_rule=True,
    attrs={
        "tool": attrs.exec_dep(
            providers=[RunInfo],
            default=select(
                {
                    "sif//constraints/rust:driver[rustc]": "sif//tools/rust:rustc",
                    "sif//constraints/rust:driver[miri]": "sif//tools/rust:miri",
                }
            ),
        ),
        "rustdoc": attrs.exec_dep(
            providers=[RunInfo],
            default="sif//tools/rust:rustdoc",
        ),
        "driver": attrs.enum(
            RustcDriver.values(),
            default=select(
                {
                    "sif//constraints/rust:driver[rustc]": "rustc",
                    "sif//constraints/rust:driver[miri]": "miri",
                }
            ),
        ),
        "target": attrs.string(default=target()),
        "sysroot": attrs.option(
            attrs.one_of(
                attrs.dep(),
                attrs.string(),
            ),
            default=select(
                {
                    "sif//constraints/rust:disable-sysroot[true]": "/dev/null",
                    "sif//constraints/rust:driver[miri]": "sif//vendor:miri-sysroot",
                    "DEFAULT": None,
                }
            ),
        ),
        "codegen_options": attrs.dict(
            key=attrs.string(),
            value=attrs.one_of(attrs.string(), attrs.list(attrs.string())),
            default={
                "debuginfo": "full",
                "target-cpu": cpu(),
                "target-feature": attributes(),
            },
        ),
        "unstable_options": attrs.dict(
            key=attrs.string(),
            value=attrs.string(),
            default=select(
                {
                    "sif//constraints/rust:driver[miri]": {
                        "miri-backtrace": "full",
                    },
                    "DEFAULT": {},
                }
            ),
        ),
    },
)
