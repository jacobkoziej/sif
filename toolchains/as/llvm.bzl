# SPDX-License-Identifier: MPL-2.0
#
# llvm.bzl -- llvm-mc assembler toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//toolchains/rules.bzl", "AsToolchainInfo")
load(
    "//tools/llvm/flags.bzl",
    "arch",
    "attributes",
    "cpu",
)


def _llvm_impl(ctx: AnalysisContext) -> list[Provider]:
    arch = "--arch=" + ctx.attrs.arch
    cpu = "-mcpu=" + ctx.attrs.cpu
    attributes = "-mattr=" + ",".join(ctx.attrs.attributes)

    tool = ctx.attrs.tool[RunInfo].args

    cmd = cmd_args(tool, "--color=true", arch, cpu, attributes)

    return [
        DefaultInfo(),
        RunInfo(
            args=cmd,
        ),
        AsToolchainInfo(
            name="llvm-mc",
            object_flags=["--filetype=obj"],
            include_prefix="-I",
        ),
    ]


llvm = rule(
    impl=_llvm_impl,
    is_toolchain_rule=True,
    attrs={
        "tool": attrs.exec_dep(providers=[RunInfo], default="//tools/llvm:mc"),
        "arch": attrs.string(default=arch()),
        "cpu": attrs.string(default=cpu()),
        "attributes": attrs.list(attrs.string(), default=attributes()),
    },
)
