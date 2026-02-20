# SPDX-License-Identifier: MPL-2.0
#
# llvm.bzl -- llvm-mc assembler toolchain
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//rules:object.bzl", "ObjectEmitterInfo")
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

    as_toolchain_info = AsToolchainInfo(
        name="llvm-mc",
        path=ctx.attrs.path[RunInfo],
        flags=[arch, cpu, attributes],
    )

    return [
        DefaultInfo(),
        as_toolchain_info,
        ObjectEmitterInfo(
            tool=as_toolchain_info.path,
            flags=as_toolchain_info.flags + ["--filetype=obj"],
        ),
    ]


llvm = rule(
    impl=_llvm_impl,
    is_toolchain_rule=True,
    attrs={
        "path": attrs.exec_dep(providers=[RunInfo], default="//tools/llvm:mc"),
        "arch": attrs.string(default=arch()),
        "cpu": attrs.string(default=cpu()),
        "attributes": attrs.list(attrs.string(), default=attributes()),
    },
)
