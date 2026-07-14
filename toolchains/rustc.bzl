# SPDX-License-Identifier: MPL-2.0
#
# rustc.bzl -- rustc toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//tools/llvm/flags.bzl",
    "attributes",
    "cpu",
)
load("@sif//tools/rustc:flags.bzl", "target")

rust_edition: str = "2024"


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

    sysroot = ctx.attrs.sysroot
    sysroot = "--sysroot={}".format(sysroot) if sysroot else []

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

    tool = ctx.attrs.tool[RunInfo].args

    cmd = cmd_args(
        tool,
        "--color=always",
        sysroot,
        edition,
        target,
        codegen_options,
        target_feature_cfgs,
        target_cpu,
    )

    return [
        DefaultInfo(),
        RunInfo(
            args=cmd,
        ),
    ]


rustc = rule(
    impl=_rustc_impl,
    is_toolchain_rule=True,
    attrs={
        "tool": attrs.exec_dep(providers=[RunInfo], default="sif//tools/rustc:rustc"),
        "target": attrs.string(default=target()),
        "sysroot": attrs.string(
            default=select(
                {
                    "sif//constraints/rustc:disable-sysroot[true]": "/dev/null",
                    "DEFAULT": "",
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
    },
)
