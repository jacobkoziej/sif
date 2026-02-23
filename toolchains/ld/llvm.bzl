# SPDX-License-Identifier: MPL-2.0
#
# llvm.bzl -- lld linker toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//toolchains/rules.bzl", "LdToolchainInfo")


def _llvm_impl(ctx: AnalysisContext) -> list[Provider]:
    return [
        DefaultInfo(),
        ctx.attrs.tool[RunInfo],
        LdToolchainInfo(
            name="lld",
            elf_flags=[
                "--gc-sections",
                "--nostdlib",
            ],
            script_flag="--script",
        ),
    ]


llvm = rule(
    impl=_llvm_impl,
    is_toolchain_rule=True,
    attrs={
        "tool": attrs.exec_dep(providers=[RunInfo], default="//tools/llvm:lld"),
    },
)
