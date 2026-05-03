# SPDX-License-Identifier: MPL-2.0
#
# rustc.bzl -- rustc toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "//tools/llvm/flags.bzl",
    "attributes",
    "cpu",
)
load("//tools/rustc:flags.bzl", "target")

rust_edition: str = "2024"


def _rustc_impl(ctx: AnalysisContext) -> list[Provider]:
    edition = "--edition=" + rust_edition
    target = "--target=" + ctx.attrs.target

    def map_codegen_option(x: tuple) -> str:
        option, value = x

        if isinstance(value, list):
            value = ",".join(value)

        return "--codegen=" + option + "=" + value

    codegen_options = map(map_codegen_option, ctx.attrs.codegen_options.items())

    tool = ctx.attrs.tool[RunInfo].args

    cmd = cmd_args(tool, "--color=always", edition, target, codegen_options)

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
        "tool": attrs.exec_dep(providers=[RunInfo], default="//tools:rustc"),
        "target": attrs.string(default=target()),
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
