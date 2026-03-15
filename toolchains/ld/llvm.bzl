# SPDX-License-Identifier: MPL-2.0
#
# llvm.bzl -- lld linker toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//toolchains/rules.bzl", "LdToolchainInfo")
load("//tools/llvm/flags.bzl", "opt_level")


def _llvm_impl(ctx: AnalysisContext) -> list[Provider]:
    tool = ctx.attrs.tool[RunInfo].args

    cmd = cmd_args(tool)

    opt_level = ctx.attrs.opt_level

    if opt_level.isdigit():
        cmd.add("-O" + ctx.attrs.opt_level)

    return [
        DefaultInfo(),
        RunInfo(
            args=cmd,
        ),
        LdToolchainInfo(
            name="lld",
            elf_flags=[
                "--gc-sections",
                "--nostdlib",
            ],
            script_flag="--script",
            dep_file_flag="--dependency-file",
        ),
    ]


llvm = rule(
    impl=_llvm_impl,
    is_toolchain_rule=True,
    attrs={
        "tool": attrs.exec_dep(providers=[RunInfo], default="//tools/llvm:lld"),
        "opt_level": attrs.string(default=opt_level()),
    },
)
